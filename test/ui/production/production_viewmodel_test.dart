import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/data/repositories/websocket_repository_impl.dart';
import 'package:gm_fabrica_monitoramento/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/data/services/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/domain/entities/batch_adjustment_entity.dart';
import 'package:gm_fabrica_monitoramento/domain/repositories/i_production_repository.dart';
import 'package:gm_fabrica_monitoramento/src/ui/production/view_models/production_viewmodel.dart';
import 'package:gm_fabrica_monitoramento/src/ui/settings/view_models/settings_viewmodel.dart';

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
  final _batchStreamController =
      StreamController<ProductionBatchEntity?>.broadcast();

  @override
  Future<List<ProductEntity>> getActiveProducts() async => products;

  @override
  Future<ProductEntity?> getProductById(String id) async {
    return products.firstWhere((p) => p.id == id);
  }

  @override
  Future<ProductionBatchEntity?> getActiveBatch() async => activeBatch;

  @override
  Stream<ProductionBatchEntity?> watchActiveBatch() =>
      _batchStreamController.stream;

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
      initialHardwareCount: initialHardwareCount,
      grossProducedCount: 0,
      discardedCount: 0,
      startedAt: DateTime.now(),
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
      activeBatch = activeBatch!.copyWith(
        grossProducedCount: grossProducedCount,
      );
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
      _batchStreamController.add(activeBatch);
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
      final newDiscard = activeBatch!.discardedCount + deltaQuantity.abs();
      activeBatch = activeBatch!.copyWith(discardedCount: newDiscard);
      _batchStreamController.add(activeBatch);
    }
  }

  @override
  Future<List<BatchAdjustmentEntity>> getAdjustmentsForBatch(
    String batchId,
  ) async => [];
}

class FakeWebSocketService implements IWebSocketService {
  final messageController = StreamController<Map<String, dynamic>>.broadcast();
  final statusController = StreamController<ConnectionStatus>.broadcast();
  final errorController = StreamController<String?>.broadcast();

  @override
  Stream<Map<String, dynamic>> get messageStream => messageController.stream;
  @override
  Stream<ConnectionStatus> get statusStream => statusController.stream;
  @override
  Stream<String?> get errorStream => errorController.stream;
  @override
  ConnectionStatus get currentStatus => ConnectionStatus.connected;
  @override
  String? get lastErrorMessage => null;
  @override
  void connect(String url) {}
  @override
  void disconnect() {}
  @override
  void dispose() {
    messageController.close();
    statusController.close();
    errorController.close();
  }
}

void main() {
  late FakeProductionRepository fakeProductionRepo;
  late FakeWebSocketService fakeWsService;
  late WebSocketRepositoryImpl webSocketRepo;
  late AudioService audioService;
  late SettingsViewModel settingsViewModel;
  late ProductionViewModel productionViewModel;

  setUp(() {
    fakeProductionRepo = FakeProductionRepository();
    fakeWsService = FakeWebSocketService();
    webSocketRepo = WebSocketRepositoryImpl(service: fakeWsService);
    audioService = AudioService(isMuted: true);
    settingsViewModel = SettingsViewModel();

    productionViewModel = ProductionViewModel(
      productionRepo: fakeProductionRepo,
      webSocketRepo: webSocketRepo,
      audioService: audioService,
      settingsViewModel: settingsViewModel,
    );
  });

  tearDown(() {
    productionViewModel.dispose();
    settingsViewModel.dispose();
    webSocketRepo.dispose();
    fakeWsService.dispose();
  });

  group('ProductionViewModel MVVM Tests', () {
    test('ESP32 Reboot Shield: protege contagem acumulada quando c_atual < c_anterior', () async {
      // 1. Início de produção normal: ESP32 envia c = 100
      fakeWsService.messageController.add({
        't': 'telem',
        'up': 10000,
        'c': 100,
      });
      await pumpEventQueue();
      expect(productionViewModel.state.dailyTotalEggs, equals(0));

      // 2. Produz 10 ovos: ESP32 envia c = 110
      fakeWsService.messageController.add({
        't': 'telem',
        'up': 20000,
        'c': 110,
      });
      await pumpEventQueue();
      expect(productionViewModel.state.dailyTotalEggs, equals(10));
      expect(productionViewModel.state.currentBoxCount, equals(10));

      // 3. ESP32 cai energia e reinicia: c volta para 3!
      fakeWsService.messageController.add({'t': 'telem', 'up': 500, 'c': 3});
      await pumpEventQueue();

      // O shield detecta o reboot e soma os 3 novos ovos ao acumulado anterior
      expect(productionViewModel.state.dailyTotalEggs, equals(13));
      expect(productionViewModel.state.currentBoxCount, equals(13));

      // 4. Continua incrementando normalmente a partir do reboot: c = 5 (+2 ovos)
      fakeWsService.messageController.add({'t': 'telem', 'up': 2000, 'c': 5});
      await pumpEventQueue();
      expect(productionViewModel.state.dailyTotalEggs, equals(15));
      expect(productionViewModel.state.currentBoxCount, equals(15));
    });

    test('Cálculo de massa total e comandos de ajuste / estorno', () async {
      await productionViewModel.startBatch('prod_250');
      await pumpEventQueue();

      final batch = productionViewModel.state.activeBatch;
      expect(batch, isNotNull);
      expect(batch!.productName, equals('Ovo Tradicional 250g'));

      // Produz 20 ovos
      fakeWsService.messageController.add({'t': 'telem', 'up': 1000, 'c': 0});
      await pumpEventQueue();
      fakeWsService.messageController.add({'t': 'telem', 'up': 2000, 'c': 20});
      await pumpEventQueue();

      expect(productionViewModel.state.batchGrossCount, equals(20));
      expect(productionViewModel.state.batchNetCount, equals(20));
      expect(
        productionViewModel.state.batchTotalWeightKg,
        equals(5.0),
      ); // 20 * 250g = 5.0 kg

      // Registra descarte de 2 ovos quebrados
      await productionViewModel.registerAdjustment(
        reason: AdjustmentReason.brokenShell,
        quantity: 2,
      );
      await pumpEventQueue();

      expect(productionViewModel.state.batchGrossCount, equals(20));
      expect(productionViewModel.state.batchDiscardedCount, equals(2));
      expect(productionViewModel.state.batchNetCount, equals(18));
      expect(
        productionViewModel.state.batchTotalWeightKg,
        equals(4.5),
      ); // 18 * 250g = 4.5 kg
    });

    test('Gestão de caixas e comandos de reset', () async {
      productionViewModel.setBoxCapacity(50);
      expect(productionViewModel.state.boxCapacity, equals(50));

      // 55 pulsos diretos
      fakeWsService.messageController.add({'t': 'telem', 'up': 1000, 'c': 0});
      await pumpEventQueue();
      fakeWsService.messageController.add({'t': 'telem', 'up': 2000, 'c': 55});
      await pumpEventQueue();

      // Completou 1 caixa e sobram 5 na caixa atual
      expect(productionViewModel.state.completedBoxesCount, equals(1));
      expect(productionViewModel.state.currentBoxCount, equals(5));
      expect(productionViewModel.state.dailyTotalEggs, equals(55));

      // Reset de caixa atual
      productionViewModel.resetCurrentBox();
      expect(productionViewModel.state.currentBoxCount, equals(0));
      expect(productionViewModel.state.dailyTotalEggs, equals(55));

      // Reset do dia
      productionViewModel.resetDailyTotal();
      expect(productionViewModel.state.dailyTotalEggs, equals(0));
      expect(productionViewModel.state.completedBoxesCount, equals(0));
      expect(productionViewModel.state.currentBoxCount, equals(0));
    });
  });
}
