import 'dart:async';

import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_motion.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/app_database.dart';
import 'package:gm_fabrica_monitoramento/src/data/remote/supabase_catalog_datasource.dart';
import 'package:gm_fabrica_monitoramento/src/data/services/audio_service.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/product_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/dashboard/ui/views/dashboard_view.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/data/freezer_repository.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/engine/freezer_adaptive_engine.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/view_models/freezer_monitoring_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/ui/views/freezer_monitoring_card.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/data/production_repository.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/view_models/egg_count_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/views/egg_count_card.dart';
import 'package:gm_fabrica_monitoramento/src/features/settings/ui/view_models/settings_view_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/settings/ui/views/settings_dialog.dart';
import 'package:gm_fabrica_monitoramento/src/features/splash/ui/views/kiosk_splash_view.dart';
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

final class FakeSupabaseCatalogDatasource implements CatalogRemoteDatasource {
  final List<ProductModel> remoteProducts;
  final List<EquipmentModel> remoteEquipments;
  final List<FreezerSensorBindingModel> savedBindings;

  FakeSupabaseCatalogDatasource({
    required this.remoteProducts,
    required this.remoteEquipments,
    List<FreezerSensorBindingModel>? initialBindings,
  }) : savedBindings = List<FreezerSensorBindingModel>.from(
         initialBindings ?? const [],
       );

  @override
  bool get isAuthenticated => true;

  @override
  String? get currentUserEmail => 'producao@gmchocolatesfinos.com.br';

  @override
  Future<List<ProductModel>> fetchActiveProducts() async => remoteProducts;

  @override
  Future<List<EquipmentModel>> fetchEquipments() async => remoteEquipments;

  @override
  Future<List<FreezerSensorBindingModel>> fetchFreezerSensorBindings() async =>
      savedBindings;

  @override
  Future<void> upsertFreezerSensorBinding(
    FreezerSensorBindingModel binding,
  ) async {
    savedBindings.removeWhere((b) => b.sensorKey == binding.sensorKey);
    savedBindings.add(binding);
  }

  @override
  void subscribeRealtime({
    VoidCallback? onProductsChanged,
    VoidCallback? onEquipmentsChanged,
    VoidCallback? onBindingsChanged,
  }) {}

  @override
  void dispose() {}
}

void main() {
  testWidgets(
    'Dashboard Kiosk 60/40 syncs Products & Equipments from Supabase, binds Freezers to Sensors and renders M3 components without overflow',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final fakeWs = WidgetTestFakeWs();
      final audioService = AudioService(isMuted: true);

      final fakeSupabaseCatalog = FakeSupabaseCatalogDatasource(
        remoteProducts: [
          ProductModel.fromSupabaseMap({
            'id': '11111111-1111-4111-8111-111111111111',
            'name': 'Ovo Ao Leite 250g',
            'category': 'ovos',
            'is_active': true,
          }),
          ProductModel.fromSupabaseMap({
            'id': '22222222-2222-4222-8222-222222222222',
            'name': 'Casca Trufada 500g',
            'category': 'cascas',
            'is_active': true,
          }),
        ],
        remoteEquipments: [
          EquipmentModel.fromSupabaseMap({
            'id': '24000000-0000-4000-8000-000000000001',
            'name': 'Freezer 1',
            'type': 'equipamento',
            'is_active': true,
          }),
          EquipmentModel.fromSupabaseMap({
            'id': '24000000-0000-4000-8000-000000000002',
            'name': 'Freezer Horizontal 500L',
            'type': 'equipamento',
            'is_active': true,
          }),
        ],
      );

      final settingsViewModel = SettingsViewModel(
        wsService: fakeWs,
        audioService: audioService,
      );
      final productionRepo = ProductionRepository(
        db.productionDao,
        fakeWs,
        remoteDatasource: fakeSupabaseCatalog,
      );
      final freezerRepo = FreezerRepository(
        freezerDao: db.freezerDao,
        wsService: fakeWs,
        productionRepo: productionRepo,
        engine: const FreezerAdaptiveEngine(),
        remoteDatasource: fakeSupabaseCatalog,
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
            Provider<CatalogRemoteDatasource>.value(value: fakeSupabaseCatalog),
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
            home: const KioskSplashView(
              duration: Duration(milliseconds: 600),
              nextChild: DashboardView(),
            ),
          ),
        ),
      );

      // Verifica renderização inicial da Tela de Splash G&M Chocolates
      expect(find.text('G&M CHOCOLATES FINOS'), findsOneWidget);
      expect(find.byKey(const ValueKey('kiosk_splash_logo')), findsOneWidget);

      // Aguarda transição automática da Splash para o Dashboard Kiosk 60/40
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Verifica renderização do Kiosk 60/40 (EggCountCard + 2 Freezers + StatusBadges + SlidingCounterText)
      expect(find.byType(EggCountCard), findsOneWidget);
      expect(find.byType(FreezerMonitoringCard), findsNWidgets(2));
      expect(find.byType(SlidingCounterText), findsOneWidget);
      expect(find.byType(StatusBadge), findsWidgets);

      // Verifica que os freezers vindos de cost_centers foram vinculados aos sensores f1 e f2
      expect(
        freezerViewModel.freezer1.value?.equipmentId,
        '24000000-0000-4000-8000-000000000001',
      );
      expect(
        freezerViewModel.freezer2.value?.equipmentId,
        '24000000-0000-4000-8000-000000000002',
      );
      expect(find.textContaining('FREEZER 1 • S1'), findsOneWidget);
      expect(
        find.textContaining('FREEZER HORIZONTAL 500L • S2'),
        findsOneWidget,
      );

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

      // 1. Abre o seletor de produto: verifica que filtra primeiramente pelos Ovos (OVOS selecionado por padrão)
      await tester.tap(find.text('INICIAR LOTE DE PRODUÇÃO'));
      await tester.pumpAndSettle();
      expect(find.text('SELECIONAR PRODUTO DO LOTE'), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_chip_ovos')), findsOneWidget);
      expect(find.text('Ovo Ao Leite 250g'), findsOneWidget);
      expect(find.text('Casca Trufada 500g'), findsNothing);
      expect(tester.takeException(), isNull);

      final eggProduct = eggViewModel.availableProducts.value
          .firstWhere((p) => p.isEgg);
      expect(eggProduct.name, 'Ovo Ao Leite 250g');
      expect(eggProduct.unitWeightGrams, 250);
      expect(eggProduct.defaultBoxCapacity, 50);

      await tester.tap(find.text(eggProduct.name));
      await tester.pumpAndSettle();
      expect(find.text('LOTE ATIVO'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Abre o modal de Ajuste/Descarte e valida o Dropdown M3, os 2 botões rápidos e o campo de digitação
      await tester.tap(find.text('AJUSTAR CONTAGEM / QUEBRA'));
      await tester.pumpAndSettle();
      expect(find.text('AJUSTAR CONTAGEM / DESCARTE'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('adjustment_reason_dropdown')),
        findsOneWidget,
      );
      expect(find.text('-1 Ovo'), findsOneWidget);
      expect(find.text('-2 Ovos'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('discard_custom_qty_input')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      // Digita quantidade manual (7 ovos quebrados) e confirma
      await tester.enterText(
        find.byKey(const ValueKey('discard_custom_qty_input')),
        '7',
      );
      await tester.tap(find.byKey(const ValueKey('discard_custom_qty_submit')));
      await tester.pumpAndSettle();
      expect(eggViewModel.dailyDiscardsCount.value, 7);
      expect(tester.takeException(), isNull);

      // 2.a Seleciona 'Correção manual' no Dropdown e verifica mudança para modo de Adição (+1 Ovo / +2 Ovos)
      await tester.tap(find.text('AJUSTAR CONTAGEM / QUEBRA'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('adjustment_reason_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Correção manual').last);
      await tester.pumpAndSettle();

      expect(find.text('+1 Ovo'), findsOneWidget);
      expect(find.text('+2 Ovos'), findsOneWidget);
      await tester.tap(find.text('+2 Ovos'));
      await tester.pumpAndSettle();
      expect(eggViewModel.currentBoxCount.value, 2);
      expect(tester.takeException(), isNull);

      // 2.b Verifica troca de produto com confirmação e encerramento com confirmação
      final cascaProduct = eggViewModel.availableProducts.value
          .firstWhere((p) => !p.isEgg);
      await tester.tap(find.byKey(const ValueKey('manage_active_batch_btn')));
      await tester.pumpAndSettle();
      expect(find.text('LOTE EM ANDAMENTO'), findsOneWidget);

      // Troca filtro para 'Todos' para visualizar produtos que não são ovos
      await tester.tap(find.byKey(const ValueKey('filter_chip_todos')));
      await tester.pumpAndSettle();
      expect(find.text(cascaProduct.name), findsOneWidget);

      // Toca em outro produto -> abre modal de confirmação de troca
      await tester.tap(find.text(cascaProduct.name));
      await tester.pumpAndSettle();
      expect(find.text('Trocar Produto em Produção?'), findsOneWidget);

      // Cancela troca -> mantém o ovo ativo
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(eggViewModel.activeBatch.value?.product.id, eggProduct.id);

      // Encerra o lote atual pelo botão dedicado com confirmação
      await tester.tap(find.byKey(const ValueKey('finish_active_batch_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Encerrar Produção do Dia?'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('confirm_finish_active_batch_btn')),
      );
      await tester.pumpAndSettle();
      expect(eggViewModel.hasActiveBatch.value, isFalse);
      expect(find.text('INICIAR LOTE DE PRODUÇÃO'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 3. Valida o Card Enxuto do Freezer: Tempo Passado / Tempo Alvo (00:00 / 08:00), Porta Fechada e botão Reiniciar
      expect(find.byType(FreezerThermalCurvePanel), findsNWidgets(2));
      expect(find.text('PORTA FECHADA'), findsNWidgets(2));
      expect(find.text('00:00 / 08:00'), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('freezer_restart_f1')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('CRISTALIZANDO'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('freezer_mark_ready_f1')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      // 3.b Simula abertura de porta no Freezer 1 (subida de 3.8 °C -> 7.8 °C) e fechamento
      fakeWs.rawDataController.add(
        BaseRawData.fromJson({
          't': 'telem',
          'boot': 1,
          'rssi': -55,
          'freeHeap': 200000,
          'totalCount': 12,
          'f1': {'temp': 5.8, 'd': 1, 'ok': 1},
          'f2': {'temp': -18.4, 'd': 0, 'ok': 1},
          'room': {'temp': 20.5, 'h': 52.0},
        }),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('PORTA ABERTA'), findsWidgets);
      expect(find.textContaining('ABERTA HÁ 00:0'), findsOneWidget);
      expect(find.textContaining('Perda: +0.0 °C ▲'), findsOneWidget);

      // Porta fecha no pico de 7.8 °C
      fakeWs.rawDataController.add(
        BaseRawData.fromJson({
          't': 'telem',
          'boot': 1,
          'rssi': -55,
          'freeHeap': 200000,
          'totalCount': 12,
          'f1': {'temp': 7.8, 'd': 0, 'ok': 1},
          'f2': {'temp': -18.4, 'd': 0, 'ok': 1},
          'room': {'temp': 20.5, 'h': 52.0},
        }),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('+2.0 °C pós-porta'), findsOneWidget);

      // 3.c Abre modal rápido de configurar tempos da porta e vínculo do Freezer 1
      await tester.tap(find.byKey(const ValueKey('freezer_config_f1')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('freezer_equipment_dropdown_f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('input_unload_seconds')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('input_reload_seconds')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('input_target_minutes')),
        '12',
      );
      await tester.tap(find.byKey(const ValueKey('save_door_timing_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('freezer_restart_f1')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('00:00 / 12:00'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 4. Abre a tela completa de Configurações e valida os dropdowns de vínculo de Sensores <-> Freezers
      await tester.tap(find.byIcon(Icons.settings_rounded), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(SettingsDialog), findsOneWidget);
      expect(
        find.byKey(const ValueKey('settings_sensor_binding_f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('settings_sensor_binding_f2')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Fechar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

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
