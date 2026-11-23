import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/core/supabase/supabase_bootstrap.dart';
import 'src/core/themes/app_theme.dart';
import 'src/data/local/app_database.dart';
import 'src/data/remote/supabase_catalog_datasource.dart';
import 'src/data/services/audio_service.dart';
import 'src/data/websocket/websocket_service.dart';
import 'src/data/websocket/websocket_service_impl.dart';
import 'src/features/auth/ui/views/kiosk_login_view.dart';
import 'src/features/dashboard/ui/views/dashboard_view.dart';
import 'src/features/freezer/data/freezer_repository.dart';
import 'src/features/freezer/domain/engine/freezer_adaptive_engine.dart';
import 'src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';
import 'src/features/production/data/production_repository.dart';
import 'src/features/production/ui/view_models/egg_count_view_model.dart';
import 'src/features/settings/ui/view_models/settings_view_model.dart';
import 'src/features/splash/ui/views/kiosk_splash_view.dart';

/// Entry point of the factory monitoring application.
/// Configures dependency injection and sets up UI, Data, and Domain layers
/// with Feature-First + Signals + Drift SQLite + Supabase Catalog architecture.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape orientation for factory wall-mount kiosk (Samsung Galaxy A05)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Immersive sticky fullscreen mode hides status and navigation bars permanently
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );
  await SystemChrome.setSystemUIChangeCallback((
    systemOverlaysAreVisible,
  ) async {
    if (systemOverlaysAreVisible) {
      await Future<void>.delayed(const Duration(seconds: 1));
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
    }
  });

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

  // 0. Supabase Backend Bootstrap (Products + Cost Centers / Freezers)
  final isSupabaseReady = await bootstrapSupabase();
  final CatalogRemoteDatasource catalogRemote = SupabaseCatalogDatasource();

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

  // 4. Data Layer: Repositories (Hot Path 0ms + Warm Path Drift Buffer + Supabase Sync)
  final productionRepo = ProductionRepository(
    database.productionDao,
    wsService,
    remoteDatasource: catalogRemote,
  );

  final freezerRepo = FreezerRepository(
    freezerDao: database.freezerDao,
    wsService: wsService,
    productionRepo: productionRepo,
    engine: const FreezerAdaptiveEngine(),
    remoteDatasource: catalogRemote,
    doorCriticalSeconds: settingsViewModel.doorCriticalSeconds,
    inspectionThresholdSeconds:
        settingsViewModel.doorInspectionThresholdSeconds,
  );

  // Inscreve no Supabase Realtime para atualizar produtos e freezers ao vivo
  if (isSupabaseReady) {
    catalogRemote.subscribeRealtime(
      onProductsChanged: () {
        productionRepo.refreshProductsFromSupabase();
      },
      onEquipmentsChanged: () {
        freezerRepo.refreshEquipmentsAndBindingsFromSupabase();
      },
      onBindingsChanged: () {
        freezerRepo.refreshEquipmentsAndBindingsFromSupabase();
      },
    );
  }

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
        Provider<CatalogRemoteDatasource>.value(value: catalogRemote),
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
      child: FactoryMonitoringApp(requireSupabaseAuth: isSupabaseReady),
    ),
  );
}

class FactoryMonitoringApp extends StatelessWidget {
  final bool requireSupabaseAuth;
  final Duration splashDuration;

  const FactoryMonitoringApp({
    super.key,
    this.requireSupabaseAuth = false,
    this.splashDuration = const Duration(milliseconds: 1800),
  });

  @override
  Widget build(BuildContext context) {
    final targetScreen = requireSupabaseAuth
        ? const _KioskAuthGate()
        : const DashboardView();

    return MaterialApp(
      title: 'G&M Fábrica - Monitoramento',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: KioskSplashView(
        duration: splashDuration,
        nextChild: targetScreen,
      ),
    );
  }
}

final class _KioskAuthGate extends StatefulWidget {
  const _KioskAuthGate();

  @override
  State<_KioskAuthGate> createState() => _KioskAuthGateState();
}

class _KioskAuthGateState extends State<_KioskAuthGate> {
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    final client = supabaseOrNull;
    _authSub = client?.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {});
      if (data.session != null) {
        _syncCatalogOnLogin();
      }
    });
  }

  void _syncCatalogOnLogin() {
    if (!mounted) return;
    final prodRepo = context.read<ProductionRepository>();
    final freezerRepo = context.read<FreezerRepository>();
    final remote = context.read<CatalogRemoteDatasource>();

    prodRepo.refreshProductsFromSupabase();
    freezerRepo.refreshEquipmentsAndBindingsFromSupabase();
    remote.subscribeRealtime(
      onProductsChanged: () => prodRepo.refreshProductsFromSupabase(),
      onEquipmentsChanged: () =>
          freezerRepo.refreshEquipmentsAndBindingsFromSupabase(),
      onBindingsChanged: () =>
          freezerRepo.refreshEquipmentsAndBindingsFromSupabase(),
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = supabaseOrNull?.auth.currentSession;
    if (session == null) {
      return KioskLoginView(
        onAuthenticated: () {
          if (mounted) {
            setState(() {});
            _syncCatalogOnLogin();
          }
        },
      );
    }
    return const DashboardView();
  }
}
