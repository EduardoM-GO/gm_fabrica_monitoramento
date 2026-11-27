import 'dart:async';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/app_database.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/enum/ws_connection_state_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/base_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/enum/type_raw_data_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/raw_data/hit_raw_data.dart';
import 'package:gm_fabrica_monitoramento/src/data/websocket/websocket_service.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/product_model.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/data/production_repository.dart';
import 'package:gm_fabrica_monitoramento/src/features/production/ui/view_models/egg_count_view_model.dart';

final class FakeWebSocketService implements WebsocketService {
  final rawDataController = StreamController<BaseRawData>.broadcast();

  @override
  Stream<WsConnectionStateEnum> get connectionStateStream =>
      const Stream.empty();

  @override
  Stream<String?> get errorStream => const Stream.empty();

  @override
  Stream<BaseRawData> get rawDataStream => rawDataController.stream;

  @override
  Future<void> connect(String host, int port) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> dispose() async {
    await rawDataController.close();
  }
}

void main() {
  late AppDatabase db;
  late FakeWebSocketService fakeWs;
  late ProductionRepository repository;

  final testProduct = ProductModel(
    id: 'prod_1',
    name: 'Ovo de Páscoa 250g',
    unitWeightGrams: 250,
    defaultBoxCapacity: 50,
  );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    // Insere produto de teste
    await db.into(db.productsTable).insert(
      ProductsTableCompanion.insert(
        id: 'prod_1',
        name: 'Ovo de Páscoa 250g',
        unitWeightGrams: 250.0,
      ),
    );

    fakeWs = FakeWebSocketService();
    repository = ProductionRepository(db.productionDao, fakeWs);
  });

  tearDown(() async {
    repository.dispose();
    await fakeWs.dispose();
    await db.close();
  });

  group('ProductionDao - Ciclo de Lotes e Contabilidade Diária', () {
    test('startBatch e getActiveBatch recuperam lote ativo com produto', () async {
      final startResult = await db.productionDao.startBatch(
        product: testProduct,
        currentHardwareCount: 100,
      );

      expect(startResult.isOk, isTrue);
      final batch = startResult.valueOrThrow;
      expect(batch.initialQuantity, 100);
      expect(batch.actualQuantity, 100);
      expect(batch.product.id, 'prod_1');
      expect(batch.product.name, 'Ovo de Páscoa 250g');

      final activeResult = await db.productionDao.getActiveBatch();
      expect(activeResult.isOk, isTrue);
      expect(activeResult.valueOrThrow, isNotNull);
      expect(activeResult.valueOrThrow!.id, batch.id);
    });

    test('autoCloseExpiredBatches encerra lote do dia anterior com dados do último hit', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      // Inicia lote simulando dia anterior
      final startResult = await db.productionDao.startBatch(
        product: testProduct,
        currentHardwareCount: 500,
      );
      final batch = startResult.valueOrThrow;

      // Altera data de início para ontem diretamente no banco
      await (db.update(db.productionBatchesTable)..where((b) => b.id.equals(batch.id))).write(
        ProductionBatchesTableCompanion(
          startedAt: Value(yesterday),
        ),
      );

      // Simula pulsos gravados ontem
      await db.productionDao.logTimelineHit(
        batchId: batch.id,
        currentHardwareCount: 750,
        timestamp: yesterday.add(const Duration(hours: 4)),
      );

      // Executa verificação de virada de dia
      final closedResult = await db.productionDao.autoCloseExpiredBatches();
      expect(closedResult.isOk, isTrue);
      expect(closedResult.valueOrThrow, 1);

      // O lote agora deve estar finalizado
      final activeResult = await db.productionDao.getActiveBatch();
      expect(activeResult.valueOrThrow, isNull);

      final lastBatchResult = await db.productionDao.getLastCompletedBatch();
      expect(lastBatchResult.valueOrThrow, isNotNull);
      expect(lastBatchResult.valueOrThrow!.id, batch.id);
      expect(lastBatchResult.valueOrThrow!.finalHardwareCount, 750);
      expect(lastBatchResult.valueOrThrow!.finishedAt, isNotNull);
    });

    test('getDailyAccounting calcula total bruto, descartes, líquido e caixas do dia', () async {
      final now = DateTime.now();

      // Inicia lote 1
      final batch1 = (await db.productionDao.startBatch(
        product: testProduct,
        currentHardwareCount: 0,
      )).valueOrThrow;

      // Produz 150 ovos no lote 1 e fecha
      await db.productionDao.closeBatch(
        batch: batch1.copyWith(actualQuantity: 150),
      );

      // Inicia lote 2 hoje com contagem 150
      final batch2 = (await db.productionDao.startBatch(
        product: testProduct,
        currentHardwareCount: 150,
      )).valueOrThrow;

      // Lote 2 atinge 250 ovos (produziu 100)
      await db.productionDao.updateBatchProgress(
        batchId: batch2.id,
        actualHardwareCount: 250,
      );

      // Registra descarte de 5 ovos (quebra)
      await db.productionDao.addAdjustment(
        batchId: batch2.id,
        deltaQty: -5,
        reason: AdjustmentReasonEnum.brokenShell,
      );

      // Consulta a contabilidade diária
      final accountingResult = await db.productionDao.getDailyAccounting(date: now);
      expect(accountingResult.isOk, isTrue);

      final accounting = accountingResult.valueOrThrow;
      // Bruto = 150 (lote 1) + 100 (lote 2) = 250
      expect(accounting.grossCount, 250);
      // Descartes = 5
      expect(accounting.discardsCount, 5);
      // Líquido = 250 - 5 = 245
      expect(accounting.netCount, 245);
      // Caixas de 50 (baseadas no líquido de cada lote): 150 ~/ 50 (3) + (100 - 5) ~/ 50 (1) = 4
      expect(accounting.completedBoxes, 4);
    });

    test('batchLogTimelineHits grava múltiplos hits em batch com sucesso', () async {
      final batch = (await db.productionDao.startBatch(
        product: testProduct,
        currentHardwareCount: 0,
      )).valueOrThrow;

      final hits = [
        (batchId: batch.id, hardwareCount: 1, timestamp: DateTime.now()),
        (batchId: batch.id, hardwareCount: 2, timestamp: DateTime.now()),
        (batchId: batch.id, hardwareCount: 3, timestamp: DateTime.now()),
      ];

      final result = await db.productionDao.batchLogTimelineHits(hits);
      expect(result.isOk, isTrue);

      final recorded = await db.select(db.productionTimeLinesTable).get();
      expect(recorded.length, 3);
    });
  });

  group('EggCountViewModel & ProductionRepository com Signals', () {
    test('Pulsos sem lote ativo disparam alerta visual de esteira sem lote', () async {
      final viewModel = EggCountViewModel(repository);

      expect(viewModel.hasActiveBatch.value, isFalse);
      expect(viewModel.isConveyorRunningWithoutBatch.value, isFalse);

      // Envia hit do hardware sem nenhum lote iniciado
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 1),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(viewModel.isConveyorRunningWithoutBatch.value, isTrue);
      expect(viewModel.hasActiveBatch.value, isFalse);

      viewModel.dispose();
    });

    test('Fluxo completo: Inicia lote, recebe pulsos com latência zero, atualiza caixa e líquido', () async {
      final viewModel = EggCountViewModel(repository);

      // Inicia lote
      final startRes = await viewModel.startBatch(testProduct);
      expect(startRes.isOk, isTrue);
      expect(viewModel.hasActiveBatch.value, isTrue);
      expect(viewModel.isConveyorRunningWithoutBatch.value, isFalse);

      // Envia 25 pulsos
      for (int i = 1; i <= 25; i++) {
        fakeWs.rawDataController.add(
          HitRawData(type: TypeRawDataEnum.hit, totalCount: i),
        );
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // 25 ovos na caixa de 50 => progresso 50%
      expect(viewModel.currentBoxCount.value, 25);
      expect(viewModel.boxProgress.value, 0.5);
      expect(viewModel.batchCompletedBoxes.value, 0);

      // Envia mais 25 pulsos (total 50)
      for (int i = 26; i <= 50; i++) {
        fakeWs.rawDataController.add(
          HitRawData(type: TypeRawDataEnum.hit, totalCount: i),
        );
      }

      await Future.delayed(const Duration(milliseconds: 50));

      // Caixa fechada: 50 ovos
      expect(viewModel.batchCompletedBoxes.value, 1);
      expect(viewModel.currentBoxCount.value, 0);

      // Registra descarte de 2 ovos quebrados (estava com 1 caixa fechada e 0/50 -> volta para 0 caixas e 48/50)
      await viewModel.addDiscards(
        reason: AdjustmentReasonEnum.brokenShell,
        quantity: 2,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(viewModel.dailyDiscardsCount.value, 2);
      expect(viewModel.batchCompletedBoxes.value, 0);
      expect(viewModel.currentBoxCount.value, 48);

      // Tentar iniciar outro produto sem encerrar o lote atual deve falhar
      final secondProduct = ProductModel(
        id: 'prod_2',
        name: 'Ovo Trufado 400g',
        unitWeightGrams: 400,
        defaultBoxCapacity: 30,
      );
      final blockedStart = await viewModel.startBatch(secondProduct);
      expect(blockedStart.isError, isTrue);
      expect(viewModel.activeBatch.value?.product.id, 'prod_1');

      // Após encerrar o lote ativo, pode iniciar outro produto
      final finishRes = await viewModel.finishActiveBatch();
      expect(finishRes.isOk, isTrue);
      expect(viewModel.hasActiveBatch.value, isFalse);

      viewModel.dispose();
    });

    test('Desconto de quebra na 1ª caixa zera em 0/50 (sem ficar negativo) e na 2ª caixa retrocede para 47/50', () async {
      final viewModel = EggCountViewModel(repository);
      await viewModel.startBatch(testProduct); // caixa de 50

      // 1ª Caixa: chegam 30 ovos (30/50)
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 30),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(viewModel.batchCompletedBoxes.value, 0);
      expect(viewModel.currentBoxCount.value, 30);

      // Quebrou 33 na 1ª caixa -> fica 0/50 (0 caixas)
      await viewModel.addDiscards(
        reason: AdjustmentReasonEnum.brokenShell,
        quantity: 33,
      );
      expect(viewModel.batchCompletedBoxes.value, 0);
      expect(viewModel.currentBoxCount.value, 0);

      // Próximo ovo passa na esteira -> continua para frente (1/50)
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 31),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(viewModel.batchCompletedBoxes.value, 0);
      expect(viewModel.currentBoxCount.value, 1);

      // Agora avança mais 79 ovos (total líquido vai de 1 para 80 -> 1 caixa fechada + 30/50 na 2ª caixa)
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 110),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(viewModel.batchCompletedBoxes.value, 1);
      expect(viewModel.currentBoxCount.value, 30);

      // Quebrou 33 na 2ª caixa -> volta para a caixa anterior em 47/50 (0 caixas fechadas)
      await viewModel.addDiscards(
        reason: AdjustmentReasonEnum.brokenShell,
        quantity: 33,
      );
      expect(viewModel.batchCompletedBoxes.value, 0);
      expect(viewModel.currentBoxCount.value, 47);

      // Próximo ovo passa na esteira -> continua para frente (48/50)
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 111),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(viewModel.batchCompletedBoxes.value, 0);
      expect(viewModel.currentBoxCount.value, 48);

      viewModel.dispose();
    });

    test('Sair e voltar no mesmo dia restaura lote ativo imediatamente e reconcilia pulsos do ESP32; na virada do dia encerra', () async {
      await repository.ready;
      final viewModel = EggCountViewModel(repository);

      // Inicia lote hoje com contagem inicial 10
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 10),
      );
      await Future.delayed(const Duration(milliseconds: 30));

      final startRes = await viewModel.startBatch(testProduct);
      expect(startRes.isOk, isTrue);

      // Produz 15 ovos (totalCount vai de 10 para 25)
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 25),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(viewModel.dailyNetCount.value, 15);

      // Simula fechamento abrupto do app (antes mesmo do timer de 1.5s do buffer)
      viewModel.dispose();
      repository.dispose();

      // Reabre o app no mesmo dia (nova instância de ProductionRepository e EggCountViewModel)
      final reopenedRepo = ProductionRepository(db.productionDao, fakeWs);
      await reopenedRepo.ready;
      final reopenedVm = EggCountViewModel(reopenedRepo);

      // Deve restaurar como LOTE ATIVO imediatamente, com os 15 ovos produzidos!
      expect(reopenedVm.hasActiveBatch.value, isTrue);
      expect(reopenedVm.activeBatch.value?.product.id, testProduct.id);
      expect(reopenedVm.dailyNetCount.value, 15);

      // Enquanto o app estava fechado, o ESP32 avançou de 25 para 40 (+15 ovos)
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 40),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(reopenedVm.dailyNetCount.value, 30);

      // Troca de produto durante o mesmo dia via switchProduct
      final secondProduct = ProductModel(
        id: 'prod_2',
        name: 'Ovo Trufado 400g',
        category: 'ovos',
        unitWeightGrams: 400,
        defaultBoxCapacity: 30,
      );
      final switchRes = await reopenedVm.switchProduct(secondProduct);
      expect(switchRes.isOk, isTrue);
      expect(reopenedVm.hasActiveBatch.value, isTrue);
      expect(reopenedVm.activeBatch.value?.product.id, 'prod_2');
      expect(reopenedVm.dailyNetCount.value, 30);

      reopenedVm.dispose();
      reopenedRepo.dispose();
    });

    test('Sincroniza produtos do Supabase sem manter nenhum mock local', () async {
      final synced = await db.productionDao.syncProductsFromSupabase([
        ProductModel.fromSupabaseMap({
          'id': 'supa_prod_1',
          'name': 'Ovo Pistache 350g',
          'category': 'ovos',
          'is_active': true,
        }),
        ProductModel.fromSupabaseMap({
          'id': 'supa_prod_2',
          'name': 'Casca Gourmet 500g',
          'category': 'cascas',
          'is_active': true,
        }),
      ]);

      expect(synced.isOk, isTrue);
      final list = synced.valueOrThrow;
      expect(list.length, 2);
      expect(list[0].name, 'Casca Gourmet 500g');
      expect(list[0].unitWeightGrams, 500);
      expect(list[0].defaultBoxCapacity, 40);
      expect(list[1].name, 'Ovo Pistache 350g');
      expect(list[1].unitWeightGrams, 350);
      expect(list[1].defaultBoxCapacity, 50);
    });

    test('Persiste room_events quando há lote ativo e dispara aviso visual de Pulso Rápido (<= 2s) na esteira', () async {
      final viewModel = EggCountViewModel(repository);
      await viewModel.startBatch(testProduct);

      // 1. Envia telemetria com dados da sala -> deve persistir na room_events_table
      fakeWs.rawDataController.add(
        BaseRawData.fromJson({
          't': 'telem',
          'boot': 1,
          'rssi': -55,
          'freeHeap': 200000,
          'totalCount': 1,
          'f1': {'temp': 2.0, 'd': 0, 'ok': 1},
          'f2': {'temp': 1.5, 'd': 0, 'ok': 1},
          'room': {'temp': 26.2, 'h': 58.0},
        }),
      );
      await Future.delayed(const Duration(milliseconds: 60));

      final roomEvents = await db.select(db.roomEventsTable).get();
      expect(roomEvents.length, equals(1));
      expect(roomEvents.first.temperature, closeTo(26.2, 0.01));
      expect(viewModel.isRoomClimateAlert.value, isTrue);

      // 2. Envia segundo pulso em menos de 2 segundos -> deve ativar alerta de Pulso Rápido sem perder a contagem
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 2),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(viewModel.dailyNetCount.value, equals(2));
      expect(viewModel.isRapidPulseWarning.value, isTrue);
      expect(
        viewModel.lastHitConfirmationText.value,
        contains('PULSO RÁPIDO'),
      );

      viewModel.dispose();
    });

    test('Continuar última caixa aberta (ex: 23 un. do lote anterior): mostra 0/27 na 1ª caixa, fecha 1 caixa com +27 ovos (Total = 27) e volta para 0/50 nas demais', () async {
      final viewModel = EggCountViewModel(repository);

      // 1. Lote anterior produziu 73 ovos (1 caixa fechada de 50 + 23 na última caixa aberta) e foi encerrado
      await viewModel.startBatch(testProduct);
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 73),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      await viewModel.finishActiveBatch();

      // Verifica que o DAO detecta automaticamente a sobra de 23 unidades da última caixa aberta
      final remRes = await viewModel.getLastOpenBoxRemainder(
        productId: testProduct.id,
        targetBoxCapacity: 50,
      );
      expect(remRes.isOk, isTrue);
      expect(remRes.valueOrThrow.carryOverUnits, equals(23));

      // Move o lote anterior para ontem no banco para simular o início de um novo dia com Total = 0
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await db.update(db.productionBatchesTable).write(
        ProductionBatchesTableCompanion(
          startedAt: Value(yesterday),
          finishedAt: Value(yesterday.add(const Duration(hours: 8))),
        ),
      );
      await viewModel.refreshDailyStats();

      // 2. Inicia novo lote hoje continuando os 23 ovos da caixa aberta (faltam 27 para fechar 50)
      final startRes = await viewModel.startBatch(
        testProduct,
        carryOverUnits: 23,
      );
      expect(startRes.isOk, isTrue);

      // No início: Caixa Atual = 0 / 27, Total de hoje = 0, Caixas Fechadas = 0
      expect(viewModel.isCompletingCarryOverBox.value, isTrue);
      expect(viewModel.currentBoxCount.value, equals(0));
      expect(viewModel.currentBoxTargetCapacity.value, equals(27));
      expect(viewModel.dailyNetCount.value, equals(0));
      expect(viewModel.batchCompletedBoxes.value, equals(0));

      // Passam 10 ovos hoje (hardware vai de 73 -> 83): Caixa Atual = 10 / 27, Total = 10, Caixas = 0
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 83),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(viewModel.isCompletingCarryOverBox.value, isTrue);
      expect(viewModel.currentBoxCount.value, equals(10));
      expect(viewModel.currentBoxTargetCapacity.value, equals(27));
      expect(viewModel.dailyNetCount.value, equals(10));
      expect(viewModel.batchCompletedBoxes.value, equals(0));

      // Passam mais 17 ovos (total hoje = 27, hardware 83 -> 100):
      // Fecha a 1ª caixa (23 + 27 = 50)! Agora Caixas Fechadas = 1, Total = 27, e a próxima caixa volta para 0 / 50!
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 100),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(viewModel.isCompletingCarryOverBox.value, isFalse);
      expect(viewModel.batchCompletedBoxes.value, equals(1));
      expect(viewModel.dailyCompletedBoxes.value, equals(1));
      expect(viewModel.dailyNetCount.value, equals(27));
      expect(viewModel.currentBoxCount.value, equals(0));
      expect(viewModel.currentBoxTargetCapacity.value, equals(50));

      // Passam mais 5 ovos (total hoje = 32, hardware 100 -> 105): Caixa Atual = 5 / 50
      fakeWs.rawDataController.add(
        HitRawData(type: TypeRawDataEnum.hit, totalCount: 105),
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(viewModel.currentBoxCount.value, equals(5));
      expect(viewModel.currentBoxTargetCapacity.value, equals(50));
      expect(viewModel.dailyNetCount.value, equals(32));
      expect(viewModel.batchCompletedBoxes.value, equals(1));

      viewModel.dispose();
    });
  });
}
