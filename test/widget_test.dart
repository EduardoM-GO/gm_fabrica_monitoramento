import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/data/repositories/websocket_repository_impl.dart';
import 'package:gm_fabrica_monitoramento/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/data/services/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/domain/entities/batch_adjustment_entity.dart';
import 'package:gm_fabrica_monitoramento/domain/entities/freezer_telemetry_entity.dart';
import 'package:gm_fabrica_monitoramento/domain/repositories/i_freezer_repository.dart';
import 'package:gm_fabrica_monitoramento/domain/repositories/i_production_repository.dart';
import 'package:gm_fabrica_monitoramento/src/ui/dashboard/views/dashboard_view.dart';
import 'package:gm_fabrica_monitoramento/src/ui/freezer/view_models/freezer_viewmodel.dart';
import 'package:gm_fabrica_monitoramento/src/ui/freezer/views/freezer_batch_card.dart';
import 'package:gm_fabrica_monitoramento/src/ui/production/view_models/production_viewmodel.dart';
import 'package:gm_fabrica_monitoramento/src/ui/production/views/egg_packaging_hero_card.dart';
import 'package:gm_fabrica_monitoramento/src/ui/settings/view_models/settings_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetTestFakeProductionRepo implements IProductionRepository {
  final List<ProductEntity> products = [
    const ProductEntity(
      id: 'prod_250',
      name: 'Ovo Tradicional 250g',
      unitWeightGrams: 250.0,
      defaultBoxCapacity: 50,
    ),
  ];
  ProductionBatchEntity? activeBatch;
  final _batchStream = StreamController<ProductionBatchEntity?>.broadcast();

  @override
  Future<List<ProductEntity>> getActiveProducts() async => products;
  @override
  Future<ProductEntity?> getProductById(String id) async => products.first;
  @override
  Future<ProductionBatchEntity?> getActiveBatch() async => activeBatch;
  @override
  Stream<ProductionBatchEntity?> watchActiveBatch() => _batchStream.stream;
  @override
  Future<void> startBatch({
    required String productId,
    required int initialHardwareCount,
  }) async {}
  @override
  Future<void> updateBatchProgress({
    required String batchId,
    required int grossProducedCount,
  }) async {}
  @override
  Future<void> pauseBatch(String batchId) async {}
  @override
  Future<void> resumeBatch(String batchId) async {}
  @override
  Future<void> finishBatch(String batchId) async {}
  @override
  Future<void> addAdjustment({
    required String batchId,
    required AdjustmentReason reason,
    required int deltaQuantity,
    String? customNote,
  }) async {}
  @override
  Future<List<BatchAdjustmentEntity>> getAdjustmentsForBatch(
    String batchId,
  ) async => [];
}

class WidgetTestFakeFreezerRepo implements IFreezerRepository {
  @override
  Future<void> recordTelemetryLog(FreezerTelemetryLogEntity log) async {}
  @override
  Future<List<FreezerTelemetryLogEntity>> getRecentLogs({
    required String freezerId,
    int limit = 60,
  }) async => [];
  @override
  Stream<List<FreezerTelemetryLogEntity>> watchRecentLogs({
    required String freezerId,
    int limit = 60,
  }) => Stream.value([]);
}

class WidgetTestFakeWs implements IWebSocketService {
  final messageController = StreamController<Map<String, dynamic>>.broadcast();
  final statusController = StreamController<ConnectionStatus>.broadcast();
  final errorController = StreamController<String?>.broadcast();

  final ConnectionStatus _status = ConnectionStatus.connected;

  @override
  Stream<Map<String, dynamic>> get messageStream => messageController.stream;
  @override
  Stream<ConnectionStatus> get statusStream => statusController.stream;
  @override
  Stream<String?> get errorStream => errorController.stream;
  @override
  ConnectionStatus get currentStatus => _status;
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
  testWidgets(
    'Dashboard dynamically displays freezers only when data is received',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final fakeWs = WidgetTestFakeWs();
      final wsRepo = WebSocketRepositoryImpl(service: fakeWs);
      final prodRepo = WidgetTestFakeProductionRepo();
      final freezerRepo = WidgetTestFakeFreezerRepo();
      final settingsViewModel = SettingsViewModel();
      final audioService = AudioService(isMuted: true);

      final productionViewModel = ProductionViewModel(
        productionRepo: prodRepo,
        webSocketRepo: wsRepo,
        audioService: audioService,
        settingsViewModel: settingsViewModel,
      );
      final freezerViewModel = FreezerViewModel(
        freezerRepo: freezerRepo,
        webSocketRepo: wsRepo,
        audioService: audioService,
        settingsViewModel: settingsViewModel,
      );

      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<IWebSocketRepository>.value(value: wsRepo),
            ChangeNotifierProvider<SettingsViewModel>.value(
              value: settingsViewModel,
            ),
            ChangeNotifierProvider<ProductionViewModel>.value(
              value: productionViewModel,
            ),
            ChangeNotifierProvider<FreezerViewModel>.value(
              value: freezerViewModel,
            ),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pump();

      // 1. Initial state (no freezer data received yet): only EggPackagingHeroCard is visible
      expect(find.byType(EggPackagingHeroCard), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byType(FreezerBatchCard), findsNothing);

      // 2. Telemetry with ONLY 1 freezer arrives (f1)
      fakeWs.messageController.add({
        't': 'telem',
        'up': 1000,
        'c': 42,
        'f1': {'temp': 3.5, 'd': 0, 'ok': 1},
      });
      await tester.pump(const Duration(milliseconds: 100));

      // Exactly 1 freezer batch card is displayed
      expect(find.byType(FreezerBatchCard), findsOneWidget);
      expect(find.text('FREEZER 1 (CÂMARA)'), findsOneWidget);
      expect(find.text('FREEZER 2 (CONGELAMENTO)'), findsNothing);

      // 3. Telemetry with 2 freezers arrives (f1 and f2)
      fakeWs.messageController.add({
        't': 'telem',
        'up': 2000,
        'c': 43,
        'f1': {'temp': 3.4, 'd': 0, 'ok': 1},
        'f2': {'temp': -18.2, 'd': 0, 'ok': 1},
      });
      await tester.pump(const Duration(milliseconds: 100));

      // Now 2 freezer batch cards are displayed
      expect(find.byType(FreezerBatchCard), findsNWidgets(2));
      expect(find.text('FREEZER 1 (CÂMARA)'), findsOneWidget);
      expect(find.text('FREEZER 2 (CONGELAMENTO)'), findsOneWidget);

      productionViewModel.dispose();
      freezerViewModel.dispose();
      settingsViewModel.dispose();
      wsRepo.dispose();
    },
  );

  testWidgets(
    'Dashboard does not overflow on small mobile (Samsung A05 / SM A055M) with 1.5x text scale',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final fakeWs = WidgetTestFakeWs();
      final wsRepo = WebSocketRepositoryImpl(service: fakeWs);
      final prodRepo = WidgetTestFakeProductionRepo();
      final freezerRepo = WidgetTestFakeFreezerRepo();
      final settingsViewModel = SettingsViewModel();
      final audioService = AudioService(isMuted: true);

      final productionViewModel = ProductionViewModel(
        productionRepo: prodRepo,
        webSocketRepo: wsRepo,
        audioService: audioService,
        settingsViewModel: settingsViewModel,
      );
      final freezerViewModel = FreezerViewModel(
        freezerRepo: freezerRepo,
        webSocketRepo: wsRepo,
        audioService: audioService,
        settingsViewModel: settingsViewModel,
      );

      // Simulating SM A055M in Landscape (1600x720 physical, DPR 1.9, textScaler 1.5x)
      tester.view.physicalSize = const Size(1600, 720);
      tester.view.devicePixelRatio = 1.9;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<IWebSocketRepository>.value(value: wsRepo),
            ChangeNotifierProvider<SettingsViewModel>.value(
              value: settingsViewModel,
            ),
            ChangeNotifierProvider<ProductionViewModel>.value(
              value: productionViewModel,
            ),
            ChangeNotifierProvider<FreezerViewModel>.value(
              value: freezerViewModel,
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: DashboardScreen(),
            ),
          ),
        ),
      );

      // Send 2 freezers
      fakeWs.messageController.add({
        't': 'telem',
        'up': 2000,
        'c': 43,
        'f1': {'temp': 3.4, 'd': 0, 'ok': 1},
        'f2': {'temp': -18.2, 'd': 0, 'ok': 1},
      });
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(EggPackagingHeroCard), findsOneWidget);
      expect(find.byType(FreezerBatchCard), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      // Also test Portrait orientation (720x1600 physical)
      tester.view.physicalSize = const Size(720, 1600);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);

      productionViewModel.dispose();
      freezerViewModel.dispose();
      settingsViewModel.dispose();
      wsRepo.dispose();
    },
  );
}
