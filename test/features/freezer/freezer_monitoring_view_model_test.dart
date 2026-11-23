import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/app_database.dart';
import 'package:gm_fabrica_monitoramento/src/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/door_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/enum/type_raw_data_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/data/freezer_repository.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_feedback_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/data/production_repository.dart';

final class SpyAudioService extends AudioService {
  final List<String> readyChimes = [];

  SpyAudioService() : super(isMuted: true);

  @override
  void playFreezerReady({String freezerId = 'f1', bool forceTest = false}) {
    readyChimes.add(freezerId);
  }
}

final class MockWs implements WebsocketService {
  final controller = StreamController<BaseRawData>.broadcast();
  @override
  Stream<WsConnectionStateEnum> get connectionStateStream => const Stream.empty();
  @override
  Stream<String?> get errorStream => const Stream.empty();
  @override
  Stream<BaseRawData> get rawDataStream => controller.stream;
  @override
  Future<void> connect(String host, int port) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> dispose() async => controller.close();
}

void main() {
  late AppDatabase db;
  late MockWs ws;
  late ProductionRepository prodRepo;
  late FreezerRepository freezerRepo;
  late SpyAudioService spyAudio;
  late FreezerMonitoringViewModel viewModel;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    await db.into(db.freezersTable).insert(
      FreezersTableCompanion.insert(
        id: 'f1',
        name: 'Freezer 1 (Câmara)',
        idSensor: 1,
      ),
    );

    ws = MockWs();
    prodRepo = ProductionRepository(db.productionDao, ws);
    freezerRepo = FreezerRepository(
      freezerDao: db.freezerDao,
      wsService: ws,
      productionRepo: prodRepo,
    );

    spyAudio = SpyAudioService();
    viewModel = FreezerMonitoringViewModel(
      freezerRepo,
      audioService: spyAudio,
      readyChimeInterval: const Duration(milliseconds: 80),
    );
    await pumpEventQueue();
  });

  tearDown(() {
    viewModel.dispose();
    freezerRepo.dispose();
    prodRepo.dispose();
    ws.dispose();
    db.close();
  });

  group('FreezerMonitoringViewModel com Signals', () {
    test('expõe signals reativos para f1 e f2', () {
      expect(viewModel.activeFreezers.value.isNotEmpty, isTrue);
      expect(viewModel.freezer1.value?.freezerId, equals('f1'));
      expect(viewModel.freezer1.value?.status, equals(FreezerStatusEnum.idle));
    });

    test('startManualCycle atualiza signal para status cooling', () async {
      await viewModel.startManualCycle('f1');
      await pumpEventQueue();

      expect(viewModel.freezer1.value?.status, equals(FreezerStatusEnum.cooling));
      expect(viewModel.freezer1.value?.remainingSeconds, greaterThan(0));
    });

    test('recordFeedback soft estende tempo e atualiza signals', () async {
      await viewModel.startManualCycle('f1');
      await viewModel.recordFeedback('f1', FreezerFeedbackEnum.soft);
      await pumpEventQueue();

      expect(viewModel.freezer1.value?.status, equals(FreezerStatusEnum.cooling));
      expect(viewModel.freezer1.value?.remainingSeconds, equals(180));
    });

    test('cancelCycle redefine freezer para idle', () async {
      await viewModel.startManualCycle('f1');
      await pumpEventQueue();
      expect(viewModel.freezer1.value?.status, equals(FreezerStatusEnum.cooling));

      viewModel.cancelCycle('f1');
      await pumpEventQueue();

      expect(viewModel.freezer1.value?.status, equals(FreezerStatusEnum.idle));
    });

    test('toca 3 vezes o alerta sonoro quando o ciclo do freezer fica pronto', () async {
      await viewModel.resetCalibration('f1', defaultSeconds: 1);
      await viewModel.startManualCycle('f1');
      await pumpEventQueue();

      // Aguarda 1s para o ciclo concluir + ~200ms para os 3 toques espaçados em 80ms
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      await pumpEventQueue();

      expect(viewModel.freezer1.value?.status, equals(FreezerStatusEnum.ready));
      expect(spyAudio.readyChimes, equals(['f1', 'f1', 'f1']));
    });

    test('interrompe os 3 toques de pronto imediatamente se a porta for aberta antes do 3º toque', () async {
      await viewModel.resetCalibration('f1', defaultSeconds: 1);
      await viewModel.startManualCycle('f1');
      await pumpEventQueue();

      // Aguarda apenas o 1º toque ao completar 1s
      await Future<void>.delayed(const Duration(milliseconds: 1030));
      await pumpEventQueue();
      expect(spyAudio.readyChimes.length, equals(1));

      // Abre a porta antes do 2º e 3º toques
      ws.controller.add(
        DoorRawData(
          type: TypeRawDataEnum.door,
          freezerId: 1,
          isOpen: true,
        ),
      );
      await pumpEventQueue();

      // Mesmo aguardando mais 250ms, os toques 2 e 3 não devem disparar
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(spyAudio.readyChimes.length, equals(1));
    });
  });
}
