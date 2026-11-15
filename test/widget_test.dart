import 'dart:async';

import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_motion.dart';
import 'package:gm_fabrica_monitoramento/src/core/themes/app_theme.dart';
import 'package:gm_fabrica_monitoramento/src/core/widgets/status_badge.dart';
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
import 'package:gm_fabrica_monitoramento/src/features/settings/ui/views/settings_dialog.dart';
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
    'Dashboard Kiosk 60/40 renders EggCountCard, Freezers, Modals and M3 components without overflow on Samsung Galaxy A05',
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

      // Verifica renderização do Kiosk 60/40 (EggCountCard + 2 Freezers + StatusBadges + SlidingCounterText)
      expect(find.byType(EggCountCard), findsOneWidget);
      expect(find.byType(FreezerMonitoringCard), findsNWidgets(2));
      expect(find.byType(SlidingCounterText), findsOneWidget);
      expect(find.byType(StatusBadge), findsWidgets);

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

      // 1. Abre o seletor de produto e inicia um lote
      await tester.tap(find.text('INICIAR LOTE DE PRODUÇÃO'));
      await tester.pumpAndSettle();
      expect(find.text('SELECIONAR PRODUTO DO LOTE'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final firstProduct = eggViewModel.availableProducts.value.first;
      await tester.tap(find.text(firstProduct.name));
      await tester.pumpAndSettle();
      expect(find.text('LOTE ATIVO'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Abre o modal de Quebra/Descarte e valida o Dropdown M3, os 2 botões rápidos e o campo de digitação
      await tester.tap(find.text('LANÇAR QUEBRA'));
      await tester.pumpAndSettle();
      expect(find.text('LANÇAR QUEBRA / DESCARTE'), findsOneWidget);
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
      await tester.tap(find.text('LANÇAR QUEBRA'));
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

      // 2.b Verifica bloqueio de troca de produto sem encerrar o lote atual
      final secondProduct = eggViewModel.availableProducts.value[1];
      await tester.tap(find.text('ENCERRAR LOTE'));
      await tester.pumpAndSettle();
      expect(find.text('LOTE EM ANDAMENTO'), findsOneWidget);

      // Tentar tocar no segundo produto enquanto o lote está ativo não troca o produto
      await tester.tap(find.text(secondProduct.name));
      await tester.pumpAndSettle();
      expect(eggViewModel.activeBatch.value?.product.id, firstProduct.id);

      // Encerra o lote atual pelo botão dedicado
      await tester.tap(find.byKey(const ValueKey('finish_active_batch_btn')));
      await tester.pumpAndSettle();
      expect(eggViewModel.hasActiveBatch.value, isFalse);
      expect(find.text('INICIAR LOTE DE PRODUÇÃO'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 3. Valida o Card Enxuto do Freezer: Tempo Passado / Tempo Alvo (00:00 / 20:00), Porta Fechada e botão tímido Reiniciar
      expect(find.byType(FreezerThermalCurvePanel), findsNWidgets(2));
      expect(find.text('PORTA FECHADA'), findsNWidgets(2));
      expect(find.text('00:00 / 20:00'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('freezer_restart_f1')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('CRISTALIZANDO'), findsOneWidget);
      expect(find.byKey(const ValueKey('freezer_cancel_f1')), findsOneWidget);
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
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('PORTA ABERTA'), findsWidgets);

      // Porta fecha no pico de 7.8 °C (+2.0 °C acima dos 5.8 °C de quando abriu)
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

      // 3.c Abre modal rápido de configurar tempos da porta no Freezer 1 e altera Tempo Alvo Base para 12 min
      await tester.tap(find.byKey(const ValueKey('freezer_config_f1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('input_unload_seconds')), findsOneWidget);
      expect(find.byKey(const ValueKey('input_reload_seconds')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('input_target_minutes')),
        '12',
      );
      await tester.tap(find.byKey(const ValueKey('save_door_timing_btn')));
      await tester.pumpAndSettle();

      // Ao clicar em Reiniciar (mesmo após subida de temperatura), deve exibir apenas o tempo base exato (00:00 / 12:00)
      await tester.tap(find.byKey(const ValueKey('freezer_restart_f1')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('00:00 / 12:00'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 4. Abre o diálogo de Configurações
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(SettingsDialog), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Fechar'));
      await tester.pump(const Duration(milliseconds: 250));

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
