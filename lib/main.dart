import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'src/core/themes/app_theme.dart';
import 'src/data/local/app_database.dart';
import 'src/data/services/audio_service.dart';
import 'src/data/websocket/websocket_service.dart';
import 'src/data/websocket/websocket_service_impl.dart';
import 'src/features/dashboard/ui/views/dashboard_view.dart';
import 'src/features/freezer/data/freezer_repository.dart';
import 'src/features/freezer/domain/engine/freezer_adaptive_engine.dart';
import 'src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';
import 'src/features/production/data/production_repository.dart';
import 'src/features/production/ui/view_models/egg_count_view_model.dart';
import 'src/features/settings/ui/view_models/settings_view_model.dart';

/// Entry point of the factory monitoring application.
/// Configures dependency injection and sets up UI, Data, and Domain layers
/// with Feature-First + Signals + Drift SQLite architecture.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape orientation for factory wall-mount kiosk (Samsung Galaxy A05)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Immersive sticky mode hides system bars to maximize display real estate
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

  // 1. Data Layer: Local Database (Drift SQLite)
  final database = AppDatabase();

  // 2. Audio Feedback Service (RAM WAV / Asset Pool)
  final audioService = AudioService();

  // 3. Hardware Pipeline (ESP32 WebSocket + Auto-Discovery)
  late final SettingsViewModel settingsViewModel;
  final WebsocketService wsService = WebsocketServiceImpl(
    onHostDiscovered: (host, port) {
      settingsViewModel.onHostDiscovered(host, port);
    },
  );

  settingsViewModel = SettingsViewModel(
    wsService: wsService,
    audioService: audioService,
  );
  // Inicia conexão assíncrona usando IP salvo ou padrão (192.168.0.58:81)
  unawaited(settingsViewModel.initAndConnect());

  // 4. Data Layer: Repositories (Hot Path 0ms + Warm Path Drift Buffer)
  final productionRepo = ProductionRepository(
    database.productionDao,
    wsService,
  );

  final freezerRepo = FreezerRepository(
    freezerDao: database.freezerDao,
    wsService: wsService,
    productionRepo: productionRepo,
    engine: const FreezerAdaptiveEngine(),
    doorCriticalSeconds: settingsViewModel.doorCriticalSeconds,
    inspectionThresholdSeconds:
        settingsViewModel.doorInspectionThresholdSeconds,
  );

  // 5. UI Layer: Feature ViewModels (100% Signals-based)
  final eggCountViewModel = EggCountViewModel(
    productionRepo,
    audioService: audioService,
  );
  final freezerMonitoringViewModel = FreezerMonitoringViewModel(
    freezerRepo,
    audioService: audioService,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        Provider<WebsocketService>.value(value: wsService),
        Provider<AudioService>.value(value: audioService),
        Provider<ProductionRepository>.value(value: productionRepo),
        Provider<FreezerRepository>.value(value: freezerRepo),
        Provider<SettingsViewModel>.value(value: settingsViewModel),
        Provider<EggCountViewModel>.value(value: eggCountViewModel),
        Provider<FreezerMonitoringViewModel>.value(
          value: freezerMonitoringViewModel,
        ),
      ],
      child: const FactoryMonitoringApp(),
    ),
  );
}

void unawaited(Future<void> future) {}

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
