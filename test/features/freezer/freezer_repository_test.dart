import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/app_database.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/door_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/enum/type_raw_data_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/freezer_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/data/freezer_repository.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/engine/freezer_adaptive_engine.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_feedback_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/data/production_repository.dart';

final class FakeWsService implements WebsocketService {
  final controller = StreamController<BaseRawData>.broadcast();

  @override
  Stream<WsConnectionStateEnum> get connectionStateStream =>
      const Stream.empty();
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
  late FakeWsService ws;
  late ProductionRepository prodRepo;
  late FreezerRepository freezerRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    // Popula freezers
    await db.into(db.freezersTable).insert(
      FreezersTableCompanion.insert(
        id: 'f1',
        name: 'Freezer 1 (Câmara)',
        idSensor: 1,
      ),
    );
    await db.into(db.freezersTable).insert(
      FreezersTableCompanion.insert(
        id: 'f2',
        name: 'Freezer 2 (Congelamento)',
        idSensor: 2,
      ),
    );

    ws = FakeWsService();
    prodRepo = ProductionRepository(db.productionDao, ws);

    freezerRepo = FreezerRepository(
      freezerDao: db.freezerDao,
      wsService: ws,
      productionRepo: prodRepo,
      engine: const FreezerAdaptiveEngine(),
      inspectionThresholdSeconds: 5, // curto para testes rápidos
    );

    await pumpEventQueue();
  });

  tearDown(() {
    freezerRepo.dispose();
    prodRepo.dispose();
    ws.dispose();
    db.close();
  });

  group('FreezerRepository - Inicialização e Telemetria', () {
    test('inicia com freezers f1 e f2 em estado idle', () {
      final f1 = freezerRepo.getFreezer('f1');
      expect(f1, isNotNull);
      expect(f1!.status, equals(FreezerStatusEnum.idle));
      expect(f1.currentTemp, equals(4.0));
    });

    test('atualiza telemetria contínua recebida via websocket', () async {
      ws.controller.add(
        FreezerRawData(
          id: 'f1',
          type: TypeRawDataEnum.telem,
          temp: 4.8,
          isDoorOpen: false,
          isSensorOk: true,
        ),
      );

      await pumpEventQueue();

      final f1 = freezerRepo.getFreezer('f1');
      expect(f1!.currentTemp, equals(4.8));
      expect(f1.temperatureHistory.isNotEmpty, isTrue);
    });
  });

  group('FreezerRepository - Ciclo Adaptativo e Penalidade', () {
    test('abertura prematura durante resfriamento aplica penalidade térmica silenciosa', () async {
      // 1. Inicia ciclo manual no f1 (1200s)
      await freezerRepo.startManualCycle('f1');
      var f1 = freezerRepo.getFreezer('f1')!;
      expect(f1.status, equals(FreezerStatusEnum.cooling));
      final initialRemaining = f1.remainingSeconds;

      // 2. Abre a porta durante o resfriamento
      ws.controller.add(
        DoorRawData(
          type: TypeRawDataEnum.door,
          freezerId: 1,
          isOpen: true,
        ),
      );
      await pumpEventQueue();

      f1 = freezerRepo.getFreezer('f1')!;
      expect(f1.status, equals(FreezerStatusEnum.doorOpen));
      expect(f1.isDoorOpen, isTrue);

      // Simula subida térmica e fecha a porta após alguns instantes
      ws.controller.add(
        FreezerRawData(
          id: 'f1',
          type: TypeRawDataEnum.telem,
          temp: 6.5,
          isDoorOpen: false,
          isSensorOk: true,
        ),
      );
      await pumpEventQueue();

      f1 = freezerRepo.getFreezer('f1')!;
      expect(f1.status, equals(FreezerStatusEnum.cooling));
      expect(f1.isDoorOpen, isFalse);
      expect(f1.accumulatedPenaltySeconds, greaterThan(0));
      expect(f1.doorOpenCount, equals(1));
      // Tempo restante deve ser maior que antes da penalidade
      expect(f1.remainingSeconds, greaterThanOrEqualTo(initialRemaining));
      expect(f1.doorDeltaTemp, closeTo(2.5, 0.01));
      expect(f1.recoveredDegrees, closeTo(0.0, 0.01));

      // Simula recuperação térmica em tempo real após a porta fechar (de 6.5 °C caiu para 4.7 °C -> recuperou 1.8 °C)
      ws.controller.add(
        FreezerRawData(
          id: 'f1',
          type: TypeRawDataEnum.telem,
          temp: 4.7,
          isDoorOpen: false,
          isSensorOk: true,
        ),
      );
      await pumpEventQueue();

      f1 = freezerRepo.getFreezer('f1')!;
      expect(f1.recoveredDegrees, closeTo(1.8, 0.01));
    });

    test('feedback "Ainda Mole" (soft) estende tempo imediatamente (+180s) e calibra futuro', () async {
      await freezerRepo.startManualCycle('f1');
      var f1 = freezerRepo.getFreezer('f1')!;
      final oldBase = f1.calibratedBaseSeconds;

      // Operador reporta "Ainda Mole"
      await freezerRepo.recordFeedback('f1', FreezerFeedbackEnum.soft);

      f1 = freezerRepo.getFreezer('f1')!;
      expect(f1.status, equals(FreezerStatusEnum.cooling));
      expect(f1.remainingSeconds, equals(180)); // +3 minutos imediatos de resfriamento
      expect(f1.calibratedBaseSeconds, greaterThan(oldBase)); // Calibração incrementada
    });

    test('feedback "No Ponto" finaliza ciclo e calibra modelo', () async {
      await freezerRepo.startManualCycle('f1');

      await freezerRepo.recordFeedback('f1', FreezerFeedbackEnum.onPoint);

      final f1 = freezerRepo.getFreezer('f1')!;
      expect(f1.status, equals(FreezerStatusEnum.idle));
      expect(f1.activeCycleId, isNull);
      expect(f1.isCalibrated, isTrue);
    });

    test('resetCalibration restaura base para default', () async {
      await freezerRepo.recordFeedback('f1', FreezerFeedbackEnum.soft);
      expect(freezerRepo.getFreezer('f1')!.isCalibrated, isTrue);

      await freezerRepo.resetCalibration('f1', defaultSeconds: 1200);

      final f1 = freezerRepo.getFreezer('f1')!;
      expect(f1.calibratedBaseSeconds, equals(1200));
      expect(f1.isCalibrated, isFalse);
    });

    test('markBatchReadyAndCalibrate finaliza lote e calibra próximo ciclo com tempo real decorrido', () async {
      await freezerRepo.startManualCycle('f1');
      final initialBase = freezerRepo.getFreezer('f1')!.calibratedBaseSeconds;

      // Simula que o operador abriu a porta antes do tempo planejado e marcou como pronto
      await Future<void>.delayed(const Duration(seconds: 2));
      await freezerRepo.markBatchReadyAndCalibrate('f1');

      final f1 = freezerRepo.getFreezer('f1')!;
      expect(f1.status, equals(FreezerStatusEnum.idle));
      expect(f1.activeCycleId, isNull);
      expect(f1.isCalibrated, isTrue);
      // Como finalizou muito antes de 1200s, o tempo base calibrado para o próximo ciclo reduz
      expect(f1.calibratedBaseSeconds, lessThan(initialBase));
    });

    test('bindEquipmentToSensor vincula equipamento do Supabase ao sensor f1 e persiste no SQLite', () async {
      final equipment = EquipmentModel(
        id: '24000000-0000-4000-8000-000000000001',
        name: 'Freezer Vertical 1',
      );

      final res = await freezerRepo.bindEquipmentToSensor(
        sensorKey: 'f1',
        equipment: equipment,
      );
      expect(res.isOk, isTrue);

      final f1 = freezerRepo.getFreezer('f1')!;
      expect(f1.equipmentId, equals('24000000-0000-4000-8000-000000000001'));
      expect(f1.equipmentName, equals('Freezer Vertical 1'));
      expect(f1.displayHeaderName, equals('Freezer Vertical 1 • S1'));

      final savedFreezers = await db.freezerDao.getFreezers();
      final savedF1 = savedFreezers.valueOrThrow.firstWhere((f) => f.id == 'f1');
      expect(savedF1.equipmentId, equals('24000000-0000-4000-8000-000000000001'));
      expect(savedF1.equipmentName, equals('Freezer Vertical 1'));
    });
  });
}
