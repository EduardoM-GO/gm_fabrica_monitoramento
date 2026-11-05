import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
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
import 'logic/freezer/freezer_cubit.dart';
import 'logic/production/production_cubit.dart';
import 'logic/settings/settings_cubit.dart';
import 'presentation/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape orientation for factory wall-mount kiosk (Samsung Galaxy A05)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Immersive sticky mode hides system bars to maximize display real estate (game mode)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Transparent system overlays for true edge-to-edge
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // 1. Local Database (Drift com Background Isolate via drift_flutter)
  final database = AppDatabase();

  // 2. Outbox Synchronization Service com Supabase
  final syncService = SupabaseSyncService(syncDao: database.syncDao);

  // 3. Repositórios Concretos
  final productionRepo = ProductionRepositoryImpl(
    dao: database.productionDao,
    syncRepo: syncService,
  );
  final freezerRepo = FreezerRepositoryImpl(
    dao: database.freezerDao,
    syncRepo: syncService,
  );

  // 4. Configurações & Áudio
  final settingsCubit = SettingsCubit();
  final audioService = AudioService(
    eggSoundEnabled: settingsCubit.state.eggSoundEnabled,
    alarmSoundEnabled: settingsCubit.state.alarmSoundEnabled,
  );

  // 5. Pipeline de Ingestão de Hardware (WebSocket)
  final IWebSocketService wsService = settingsCubit.state.isMockEnabled
      ? MockWebSocketService()
      : WebSocketServiceImpl();
  final wsRepo = WebSocketRepositoryImpl(service: wsService);
  wsRepo.connect(settingsCubit.state.wsUrl);

  // 6. Cubits de Domínio
  final productionCubit = ProductionCubit(
    productionRepo: productionRepo,
    webSocketRepo: wsRepo,
    audioService: audioService,
    settingsCubit: settingsCubit,
  );

  final freezerCubit = FreezerCubit(
    freezerRepo: freezerRepo,
    webSocketRepo: wsRepo,
    audioService: audioService,
    settingsCubit: settingsCubit,
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: database),
        RepositoryProvider<ISyncRepository>.value(value: syncService),
        RepositoryProvider<IProductionRepository>.value(value: productionRepo),
        RepositoryProvider<IFreezerRepository>.value(value: freezerRepo),
        RepositoryProvider<IWebSocketRepository>.value(value: wsRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
          BlocProvider<ProductionCubit>.value(value: productionCubit),
          BlocProvider<FreezerCubit>.value(value: freezerCubit),
        ],
        child: const FactoryMonitoringApp(),
      ),
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
      home: const DashboardScreen(),
    );
  }
}
