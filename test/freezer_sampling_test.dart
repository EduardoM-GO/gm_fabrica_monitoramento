import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/data/models/telemetry_model.dart';
import 'package:gm_fabrica_monitoramento/data/repositories/websocket_repository_impl.dart';
import 'package:gm_fabrica_monitoramento/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/data/services/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/domain/entities/freezer_telemetry_entity.dart';
import 'package:gm_fabrica_monitoramento/domain/repositories/i_freezer_repository.dart';
import 'package:gm_fabrica_monitoramento/logic/freezer/freezer_cubit.dart';
import 'package:gm_fabrica_monitoramento/logic/settings/settings_cubit.dart';

class FakeFreezerRepository implements IFreezerRepository {
  final List<FreezerTelemetryLogEntity> recordedLogs = [];

  @override
  Future<void> recordTelemetryLog(FreezerTelemetryLogEntity log) async {
    recordedLogs.add(log);
  }

  @override
  Future<List<FreezerTelemetryLogEntity>> getRecentLogs({
    required String freezerId,
    int limit = 60,
  }) async {
    return recordedLogs.where((l) => l.freezerId == freezerId).toList();
  }

  @override
  Stream<List<FreezerTelemetryLogEntity>> watchRecentLogs({
    required String freezerId,
    int limit = 60,
  }) {
    return Stream.value(recordedLogs.where((l) => l.freezerId == freezerId).toList());
  }
}

class FakeWebSocketRepository implements IWebSocketRepository {
  final _hitController = StreamController<HitFrame>.broadcast();
  final _telemController = StreamController<TelemetryFrame>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _errorController = StreamController<String?>.broadcast();

  @override Stream<HitFrame> get hitStream => _hitController.stream;
  @override Stream<TelemetryFrame> get telemetryStream => _telemController.stream;
  @override Stream<ConnectionStatus> get connectionStatusStream => _statusController.stream;
  @override Stream<String?> get errorStream => _errorController.stream;
  @override ConnectionStatus get currentStatus => ConnectionStatus.connected;
  @override void connect(String url) {}
  @override void disconnect() {}
  @override void dispose() {}
  @override void simulateEggHit() {}
  @override void toggleSimulatorDoor(int freezerNum) {}
  @override void toggleSimulatorProbe(int freezerNum) {}

  void emitTelem({
    required int uptime,
    required double f1Temp,
    required int f1Door,
    required int f1Ok,
  }) {
    _telemController.add(
      TelemetryFrame(
        uptimeMs: uptime,
        eggCount: 100,
        freezer1: FreezerRawData(temp: f1Temp, door: f1Door, ok: f1Ok),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFreezerRepository fakeRepo;
  late FakeWebSocketRepository fakeWs;
  late SettingsCubit settingsCubit;
  late AudioService audioService;
  late FreezerCubit cubit;

  setUp(() {
    fakeRepo = FakeFreezerRepository();
    fakeWs = FakeWebSocketRepository();
    settingsCubit = SettingsCubit();
    audioService = AudioService(isMuted: true);
    cubit = FreezerCubit(
      freezerRepo: fakeRepo,
      webSocketRepo: fakeWs,
      audioService: audioService,
      settingsCubit: settingsCubit,
    );
  });

  tearDown(() async {
    await cubit.close();
    await settingsCubit.close();
  });

  test('Amostragem Híbrida: leituras idênticas NÃO sobrecarregam o banco com 60 gravações', () async {
    // Simula 10 frames idênticos em menos de 10 segundos
    for (int i = 0; i < 10; i++) {
      fakeWs.emitTelem(uptime: i * 1000, f1Temp: 4.0, f1Door: 0, f1Ok: 1);
      await pumpEventQueue();
    }

    // Deve registrar apenas 1 gravação inicial
    expect(fakeRepo.recordedLogs.length, equals(1));
    expect(fakeRepo.recordedLogs.first.triggerReason, equals('initial'));
  });

  test('Gatilho de Evento: abertura de porta grava IMEDIATAMENTE no Drift', () async {
    // Leitura 1: porta fechada
    fakeWs.emitTelem(uptime: 1000, f1Temp: 4.0, f1Door: 0, f1Ok: 1);
    await pumpEventQueue();
    expect(fakeRepo.recordedLogs.length, equals(1));

    // Leitura 2: porta acabou de abrir (d: 1)
    fakeWs.emitTelem(uptime: 2000, f1Temp: 4.0, f1Door: 1, f1Ok: 1);
    await pumpEventQueue();

    // Deve registrar imediatamente
    expect(fakeRepo.recordedLogs.length, equals(2));
    expect(fakeRepo.recordedLogs.last.triggerReason, equals('event_door'));
    expect(fakeRepo.recordedLogs.last.isDoorOpen, isTrue);
  });

  test('Gatilho de Falha: sonda desconectada (ok == 0) grava IMEDIATAMENTE no Drift', () async {
    fakeWs.emitTelem(uptime: 1000, f1Temp: 4.0, f1Door: 0, f1Ok: 1);
    await pumpEventQueue();

    // Sonda cai (ok: 0)
    fakeWs.emitTelem(uptime: 2000, f1Temp: 4.0, f1Door: 0, f1Ok: 0);
    await pumpEventQueue();

    expect(fakeRepo.recordedLogs.length, equals(2));
    expect(fakeRepo.recordedLogs.last.triggerReason, equals('event_probe'));
    expect(fakeRepo.recordedLogs.last.isSensorOk, isFalse);
  });

  test('Gatilho Térmico: variação de temperatura >= 0.5C grava no Drift', () async {
    fakeWs.emitTelem(uptime: 1000, f1Temp: 4.0, f1Door: 0, f1Ok: 1);
    await pumpEventQueue();

    // Variação de 0.2C -> não deve gravar
    fakeWs.emitTelem(uptime: 2000, f1Temp: 4.2, f1Door: 0, f1Ok: 1);
    await pumpEventQueue();
    expect(fakeRepo.recordedLogs.length, equals(1));

    // Variação para 4.6C (delta de 0.6C desde 4.0) -> DEVE gravar!
    fakeWs.emitTelem(uptime: 3000, f1Temp: 4.6, f1Door: 0, f1Ok: 1);
    await pumpEventQueue();

    expect(fakeRepo.recordedLogs.length, equals(2));
    expect(fakeRepo.recordedLogs.last.triggerReason, equals('delta_temp_0.5'));
    expect(fakeRepo.recordedLogs.last.temperature, equals(4.6));
  });
}

