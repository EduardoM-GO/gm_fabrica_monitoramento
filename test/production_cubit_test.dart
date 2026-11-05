import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/data/models/telemetry_model.dart';
import 'package:gm_fabrica_monitoramento/data/repositories/websocket_repository_impl.dart';
import 'package:gm_fabrica_monitoramento/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/data/services/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/domain/entities/batch_adjustment_entity.dart';
import 'package:gm_fabrica_monitoramento/domain/entities/product_entity.dart';
import 'package:gm_fabrica_monitoramento/domain/entities/production_batch_entity.dart';
import 'package:gm_fabrica_monitoramento/domain/repositories/i_production_repository.dart';
import 'package:gm_fabrica_monitoramento/logic/production/production_cubit.dart';
import 'package:gm_fabrica_monitoramento/logic/settings/settings_cubit.dart';

class FakeProductionRepository implements IProductionRepository {
  final List<ProductEntity> products = [
    const ProductEntity(
      id: 'prod_250',
      name: 'Ovo Tradicional 250g',
      unitWeightGrams: 250.0,
      defaultBoxCapacity: 50,
    ),
  ];
  ProductionBatchEntity? activeBatch;
  final _batchStreamController = StreamController<ProductionBatchEntity?>.broadcast();

  @override
  Future<List<ProductEntity>> getActiveProducts() async => products;

  @override
  Future<ProductEntity?> getProductById(String id) async {
    return products.firstWhere((p) => p.id == id);
  }

  @override
  Future<ProductionBatchEntity?> getActiveBatch() async => activeBatch;

  @override
  Stream<ProductionBatchEntity?> watchActiveBatch() => _batchStreamController.stream;

  @override
  Future<void> startBatch({
    required String productId,
    required int initialHardwareCount,
  }) async {
    final prod = await getProductById(productId);
    activeBatch = ProductionBatchEntity(
      id: 'batch_test_1',
      productId: productId,
      productName: prod?.name ?? 'Test',
      unitWeightGrams: prod?.unitWeightGrams ?? 250.0,
      startedAt: DateTime.now(),
      initialHardwareCount: initialHardwareCount,
      grossProducedCount: 0,
      discardedCount: 0,
      status: BatchStatus.inProgress,
      isSynced: false,
    );
    _batchStreamController.add(activeBatch);
  }

  @override
  Future<void> updateBatchProgress({
    required String batchId,
    required int grossProducedCount,
  }) async {
    if (activeBatch != null && activeBatch!.id == batchId) {
      activeBatch = activeBatch!.copyWith(grossProducedCount: grossProducedCount);
      _batchStreamController.add(activeBatch);
    }
  }

  @override
  Future<void> pauseBatch(String batchId) async {
    if (activeBatch != null) {
      activeBatch = activeBatch!.copyWith(status: BatchStatus.paused);
      _batchStreamController.add(activeBatch);
    }
  }

  @override
  Future<void> resumeBatch(String batchId) async {
    if (activeBatch != null) {
      activeBatch = activeBatch!.copyWith(status: BatchStatus.inProgress);
      _batchStreamController.add(activeBatch);
    }
  }

  @override
  Future<void> finishBatch(String batchId) async {
    if (activeBatch != null) {
      activeBatch = activeBatch!.copyWith(
        status: BatchStatus.completed,
        finishedAt: DateTime.now(),
      );
      _batchStreamController.add(null);
    }
  }

  @override
  Future<void> addAdjustment({
    required String batchId,
    required AdjustmentReason reason,
    required int deltaQuantity,
    String? customNote,
  }) async {
    if (activeBatch != null && activeBatch!.id == batchId) {
      final newDiscarded = activeBatch!.discardedCount + deltaQuantity.abs();
      activeBatch = activeBatch!.copyWith(discardedCount: newDiscarded);
      _batchStreamController.add(activeBatch);
    }
  }

  @override
  Future<List<BatchAdjustmentEntity>> getAdjustmentsForBatch(String batchId) async => [];
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

  void emitHit(int c) => _hitController.add(HitFrame(eggCount: c));
  void emitTelem(int c, int up) => _telemController.add(TelemetryFrame(uptimeMs: up, eggCount: c));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeProductionRepository fakeProductionRepo;
  late FakeWebSocketRepository fakeWsRepo;
  late SettingsCubit settingsCubit;
  late AudioService audioService;
  late ProductionCubit cubit;

  setUp(() {
    fakeProductionRepo = FakeProductionRepository();
    fakeWsRepo = FakeWebSocketRepository();
    settingsCubit = SettingsCubit();
    audioService = AudioService(isMuted: true);
    cubit = ProductionCubit(
      productionRepo: fakeProductionRepo,
      webSocketRepo: fakeWsRepo,
      audioService: audioService,
      settingsCubit: settingsCubit,
    );
  });

  tearDown(() async {
    await cubit.close();
    await settingsCubit.close();
  });

  test('ESP32 Reboot Shield: protege contagem acumulada quando c_atual < c_anterior', () async {
    await cubit.startBatch('prod_250');
    await pumpEventQueue();

    // Pulso inicial c = 100
    fakeWsRepo.emitHit(100);
    await pumpEventQueue();
    expect(cubit.state.batchGrossCount, equals(1)); // Primeira detecção

    // Pulso c = 110 (delta = 10)
    fakeWsRepo.emitHit(110);
    await pumpEventQueue();
    expect(cubit.state.batchGrossCount, equals(11));

    // REBOOT DO ESP32! Contador cai para c = 3 (devido a oscilação de energia da fábrica)
    fakeWsRepo.emitHit(3);
    await pumpEventQueue();

    // O acumulado do lote DEVE somar 3 ao total anterior (11 + 3 = 14) sem jamais zerar ou decrementar!
    expect(cubit.state.batchGrossCount, equals(14));
    expect(cubit.state.lastRawHardwareCount, equals(3));
  });

  test('Cálculo de massa total e estorno de quebras', () async {
    await cubit.startBatch('prod_250');
    await pumpEventQueue();

    // Produz 20 ovos (250g cada = 5.0 kg)
    fakeWsRepo.emitHit(10);
    fakeWsRepo.emitHit(30);
    await pumpEventQueue();

    expect(cubit.state.batchGrossCount, equals(21));
    expect(cubit.state.batchNetCount, equals(21));
    expect(cubit.state.batchTotalWeightKg, closeTo(5.25, 0.01));

    // Registra estorno de 3 cascas quebradas
    await cubit.registerAdjustment(
      reason: AdjustmentReason.brokenShell,
      quantity: 3,
    );
    await pumpEventQueue();

    // Líquido: 21 - 3 = 18 ovos. Massa: 18 * 0.25kg = 4.5 kg
    expect(cubit.state.batchDiscardedCount, equals(3));
    expect(cubit.state.batchNetCount, equals(18));
    expect(cubit.state.batchTotalWeightKg, closeTo(4.5, 0.01));
  });

  test('Gestão de caixas e reset diário', () async {
    cubit.setBoxCapacity(50);
    expect(cubit.state.boxCapacity, equals(50));

    // Incrementos manuais
    cubit.incrementManual();
    cubit.incrementManual();
    expect(cubit.state.currentBoxCount, equals(2));
    expect(cubit.state.dailyTotalEggs, equals(2));

    // Decremento manual
    cubit.decrementManual();
    expect(cubit.state.currentBoxCount, equals(1));
    expect(cubit.state.dailyTotalEggs, equals(1));

    // Reset da caixa atual
    cubit.resetCurrentBox();
    expect(cubit.state.currentBoxCount, equals(0));
    expect(cubit.state.dailyTotalEggs, equals(1)); // Total do dia preservado
  });
}
