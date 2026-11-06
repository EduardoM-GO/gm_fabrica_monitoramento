import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/datasources/local/app_database.dart';
import 'data/datasources/remote/supabase_sync_service.dart';
import 'data/repositories/freezer_repository_impl.dart';
import 'data/repositories/production_repository_impl.dart';
import 'data/repositories/websocket_repository_impl.dart';
import 'data/services/audio_service.dart';
import 'data/services/mock_telemetry_generator.dart';
import 'data/services/websocket_service.dart';
import 'domain/repositories/i_freezer_repository.dart';
import 'domain/repositories/i_production_repository.dart';
import 'domain/repositories/i_sync_repository.dart';
import 'src/core/themes/app_theme.dart';
import 'src/ui/dashboard/views/dashboard_view.dart';
import 'src/ui/freezer/view_models/freezer_viewmodel.dart';
import 'src/ui/production/view_models/production_viewmodel.dart';
import 'src/ui/settings/view_models/settings_viewmodel.dart';

/// Entry point of the factory monitoring application.
/// Configures dependency injection and sets up UI, Data, and Domain layers
/// according to the official Flutter App Architecture (docs.flutter.dev/app-architecture).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape orientation for factory wall-mount kiosk (Samsung Galaxy A05)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Immersive sticky mode hides system bars to maximize display real estate (game mode)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Transparent system overlays for edge-to-edge layout
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 1. Data Layer: Local Database (Drift with Background Isolate via drift_flutter)
  final database = AppDatabase();

  // 2. Data Layer: Outbox Synchronization Service with Supabase
  final syncService = SupabaseSyncService(syncDao: database.syncDao);

  // 3. Data Layer: Repositories (Single source of truth)
  final productionRepo = ProductionRepositoryImpl(
    dao: database.productionDao,
    syncRepo: syncService,
  );
  final freezerRepo = FreezerRepositoryImpl(
    dao: database.freezerDao,
    syncRepo: syncService,
  );

  // 4. UI Layer: Settings ViewModel & Audio Service
  final settingsViewModel = SettingsViewModel();
  final audioService = AudioService(
    eggSoundEnabled: settingsViewModel.eggSoundEnabled,
    alarmSoundEnabled: settingsViewModel.alarmSoundEnabled,
  );

  // 5. Data Layer: Hardware Pipeline (ESP32 WebSocket or Simulator)
  final IWebSocketService wsService = settingsViewModel.isMockEnabled
      ? MockWebSocketService()
      : WebSocketServiceImpl();
  final wsRepo = WebSocketRepositoryImpl(service: wsService);
  wsRepo.connect(settingsViewModel.wsUrl);

  // 6. UI Layer: Feature ViewModels (MVVM State Holders with Command pattern)
  final productionViewModel = ProductionViewModel(
    productionRepo: productionRepo,
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

  runApp(
    MultiProvider(
      providers: [
        // Data & Domain Layer Dependencies
        Provider<AppDatabase>.value(value: database),
        Provider<ISyncRepository>.value(value: syncService),
        Provider<IProductionRepository>.value(value: productionRepo),
        Provider<IFreezerRepository>.value(value: freezerRepo),
        Provider<IWebSocketRepository>.value(value: wsRepo),
        Provider<AudioService>.value(value: audioService),

        // UI Layer State Holders (ViewModels)
        ChangeNotifierProvider<SettingsViewModel>.value(
          value: settingsViewModel,
        ),
        ChangeNotifierProvider<ProductionViewModel>.value(
          value: productionViewModel,
        ),
        ChangeNotifierProvider<FreezerViewModel>.value(value: freezerViewModel),
      ],
      child: const FactoryMonitoringApp(),
    ),
  );
}

class FactoryMonitoringApp extends StatelessWidget {
  const FactoryMonitoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GM Fábrica - Monitoramento',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardView(),
    );
  }
}
