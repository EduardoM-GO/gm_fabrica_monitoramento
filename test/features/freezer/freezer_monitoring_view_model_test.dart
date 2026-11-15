import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/app_database.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/data/freezer_repository.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_feedback_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/data/production_repository.dart';

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

    viewModel = FreezerMonitoringViewModel(freezerRepo);
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
  });
}
