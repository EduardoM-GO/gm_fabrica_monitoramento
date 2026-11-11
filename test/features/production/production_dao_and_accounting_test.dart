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
      // Caixas de 50: 150 ~/ 50 (3) + 100 ~/ 50 (2) = 5
      expect(accounting.completedBoxes, 5);
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

      // Registra descarte de 2 ovos quebrados
      await viewModel.addDiscards(
        reason: AdjustmentReasonEnum.brokenShell,
        quantity: 2,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(viewModel.dailyDiscardsCount.value, 2);

      viewModel.dispose();
    });
  });
}
