import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/data/datasources/local/app_database.dart';
import 'package:gm_fabrica_monitoramento/data/datasources/remote/supabase_sync_service.dart';
import 'package:gm_fabrica_monitoramento/data/repositories/freezer_repository_impl.dart';
import 'package:gm_fabrica_monitoramento/data/repositories/production_repository_impl.dart';
import 'package:gm_fabrica_monitoramento/data/repositories/websocket_repository_impl.dart';
import 'package:gm_fabrica_monitoramento/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/data/services/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/logic/freezer/freezer_cubit.dart';
import 'package:gm_fabrica_monitoramento/logic/production/production_cubit.dart';
import 'package:gm_fabrica_monitoramento/logic/settings/settings_cubit.dart';
import 'package:gm_fabrica_monitoramento/presentation/dashboard_screen.dart';
import 'package:gm_fabrica_monitoramento/presentation/widgets/egg_packaging_hero_card.dart';
import 'package:gm_fabrica_monitoramento/presentation/widgets/freezer_batch_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Dashboard dynamically displays freezers only when data is received',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final fakeWs = WidgetTestFakeWs();
    final wsRepo = WebSocketRepositoryImpl(service: fakeWs);
    final db = AppDatabase(NativeDatabase.memory());
    final syncService = SupabaseSyncService(syncDao: db.syncDao);
    final prodRepo = ProductionRepositoryImpl(dao: db.productionDao, syncRepo: syncService);
    final freezerRepo = FreezerRepositoryImpl(dao: db.freezerDao, syncRepo: syncService);
    final settingsCubit = SettingsCubit();
    final audioService = AudioService(isMuted: true);

    final productionCubit = ProductionCubit(
      productionRepo: prodRepo,
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

    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
          BlocProvider<ProductionCubit>.value(value: productionCubit),
          BlocProvider<FreezerCubit>.value(value: freezerCubit),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
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

    await productionCubit.close();
    await freezerCubit.close();
    await settingsCubit.close();
    await db.close();
    wsRepo.dispose();
  });

  testWidgets(
      'Dashboard does not overflow on small mobile (Samsung A05 / SM A055M) with 1.5x text scale',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final fakeWs = WidgetTestFakeWs();
    final wsRepo = WebSocketRepositoryImpl(service: fakeWs);
    final db = AppDatabase(NativeDatabase.memory());
    final syncService = SupabaseSyncService(syncDao: db.syncDao);
    final prodRepo = ProductionRepositoryImpl(dao: db.productionDao, syncRepo: syncService);
    final freezerRepo = FreezerRepositoryImpl(dao: db.freezerDao, syncRepo: syncService);
    final settingsCubit = SettingsCubit();
    final audioService = AudioService(isMuted: true);

    final productionCubit = ProductionCubit(
      productionRepo: prodRepo,
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

    // Simulating SM A055M in Landscape (1600x720 physical, DPR 1.9, textScaler 1.5x)
    tester.view.physicalSize = const Size(1600, 720);
    tester.view.devicePixelRatio = 1.9;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
          BlocProvider<ProductionCubit>.value(value: productionCubit),
          BlocProvider<FreezerCubit>.value(value: freezerCubit),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(1.5),
            ),
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

    await productionCubit.close();
    await freezerCubit.close();
    await settingsCubit.close();
    await db.close();
    wsRepo.dispose();
  });
}
