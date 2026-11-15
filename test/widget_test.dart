import 'dart:async';

import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/app_database.dart';
import 'package:gm_fabrica_monitoramento/src/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/src/features/dashboard/ui/views/dashboard_view.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/data/freezer_repository.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/engine/freezer_adaptive_engine.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/views/freezer_monitoring_card.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/data/production_repository.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/view_models/egg_count_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/views/egg_count_card.dart';
import 'package:gm_fabrica_monitoramento/src/features/settings/ui/view_models/settings_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class WidgetTestFakeWs implements WebsocketService {
  final rawDataController = StreamController<BaseRawData>.broadcast();
  final stateController = StreamController<WsConnectionStateEnum>.broadcast();
  final errorController = StreamController<String?>.broadcast();

  @override
  Stream<WsConnectionStateEnum> get connectionStateStream =>
      stateController.stream;

  @override
  Stream<String?> get errorStream => errorController.stream;

  @override
  Stream<BaseRawData> get rawDataStream => rawDataController.stream;

  @override
  Future<void> connect(String host, int port) async {
    stateController.add(WsConnectionStateEnum.connected);
  }

  @override
  Future<void> disconnect() async {
    stateController.add(WsConnectionStateEnum.disconnected);
  }

  @override
  Future<void> dispose() async {
    await rawDataController.close();
    await stateController.close();
    await errorController.close();
  }
}

void main() {
  testWidgets(
    'Dashboard Kiosk 60/40 renders EggCountCard and Freezers without overflow on Samsung Galaxy A05',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final fakeWs = WidgetTestFakeWs();
      final audioService = AudioService(isMuted: true);

      final settingsViewModel = SettingsViewModel(
        wsService: fakeWs,
        audioService: audioService,
      );
      final productionRepo = ProductionRepository(db.productionDao, fakeWs);
      final freezerRepo = FreezerRepository(
        freezerDao: db.freezerDao,
        wsService: fakeWs,
        productionRepo: productionRepo,
        engine: const FreezerAdaptiveEngine(),
      );

      final eggViewModel = EggCountViewModel(
        productionRepo,
        audioService: audioService,
      );
      final freezerViewModel = FreezerMonitoringViewModel(
        freezerRepo,
        audioService: audioService,
      );

      // Samsung Galaxy A05 Landscape (1600x720 physical, DPR 1.9)
      tester.view.physicalSize = const Size(1600, 720);
      tester.view.devicePixelRatio = 1.9;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppDatabase>.value(value: db),
            Provider<WebsocketService>.value(value: fakeWs),
            Provider<AudioService>.value(value: audioService),
            Provider<ProductionRepository>.value(value: productionRepo),
            Provider<FreezerRepository>.value(value: freezerRepo),
            Provider<SettingsViewModel>.value(value: settingsViewModel),
            Provider<EggCountViewModel>.value(value: eggViewModel),
            Provider<FreezerMonitoringViewModel>.value(value: freezerViewModel),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const DashboardView(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verifica renderização do Kiosk 60/40 (EggCountCard + 2 Freezers)
      expect(find.byType(EggCountCard), findsOneWidget);
      expect(find.byType(FreezerMonitoringCard), findsNWidgets(2));

      // Envia frame de telemetria completo (2 freezers + sala + contador)
      fakeWs.rawDataController.add(
        BaseRawData.fromJson({
          't': 'telem',
          'boot': 1,
          'rssi': -55,
          'freeHeap': 200000,
          'totalCount': 12,
          'f1': {'temp': 3.8, 'd': 0, 'ok': 1},
          'f2': {'temp': -18.4, 'd': 0, 'ok': 1},
          'room': {'temp': 20.5, 'h': 52.0},
        }),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('20.5 °C'), findsOneWidget);
      expect(find.textContaining('3.8 °C'), findsOneWidget);
      expect(find.textContaining('-18.4 °C'), findsOneWidget);
      expect(tester.takeException(), isNull);

      eggViewModel.dispose();
      freezerViewModel.dispose();
      settingsViewModel.dispose();
      freezerRepo.dispose();
      productionRepo.dispose();
      await fakeWs.dispose();
      await db.close();
    },
  );
}
