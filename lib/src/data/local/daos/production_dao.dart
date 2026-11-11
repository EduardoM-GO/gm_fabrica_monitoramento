import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/daily_production_accounting_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/product_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/production_batch_model.dart';
import 'package:gm_fabrica_monitoramento/src/utils/generator_id.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';

import '../app_database.dart';
import '../tables/production_batches_table.dart';
import '../tables/batch_adjustments_table.dart';
import '../tables/production_time_lines_table.dart';
import '../tables/products_table.dart';
import '../enum/adjustment_reason_enum.dart';
import '../enum/sync_status_enum.dart';

part 'production_dao.g.dart';

@DriftAccessor(
  tables: [
    ProductionBatchesTable,
    BatchAdjustmentsTable,
    ProductionTimeLinesTable,
    ProductsTable,
  ],
)
final class ProductionDao extends DatabaseAccessor<AppDatabase>
    with _$ProductionDaoMixin {
  ProductionDao(super.db);

  /// Inicia um novo lote de produção com a contagem atual do hardware
  Future<Result<ProductionBatchModel>> startBatch({
    required ProductModel product,
    int? currentHardwareCount,
  }) => Result.catchInAsync(
    fn: () async {
      // Finaliza automaticamente qualquer lote pendente anterior antes de iniciar novo
      await autoCloseExpiredBatches();

      // Se não foi passado currentHardwareCount explicitamente, busca do último lote finalizado
      int initialCount = currentHardwareCount ?? 0;
      if (currentHardwareCount == null) {
        final lastBatchResult = await getLastCompletedBatch();
        if (lastBatchResult.isOk && lastBatchResult.valueOrThrow != null) {
          initialCount = lastBatchResult.valueOrThrow!.finalHardwareCount ?? 0;
        }
      }

      final batch = ProductionBatchModel(
        product: product,
        initialQuantity: initialCount,
        actualQuantity: initialCount,
        startedAt: DateTime.now(),
      );

      await into(productionBatchesTable).insert(
        ProductionBatchesTableCompanion.insert(
          id: batch.id,
          productId: batch.product.id,
          initialHardwareCount: batch.initialQuantity,
          startedAt: Value(batch.startedAt),
        ),
      );

      return batch;
    },
    tag: 'ProductionDao.startBatch',
  );

  /// Retorna o último lote concluído
  Future<Result<ProductionBatch?>> getLastCompletedBatch() =>
      Result.catchInAsync(
        fn: () async {
          return await (select(productionBatchesTable)
                ..where((b) => b.finishedAt.isNotNull())
                ..orderBy([
                  (b) => OrderingTerm(
                    expression: b.finishedAt,
                    mode: OrderingMode.desc,
                  ),
                ]))
              .getSingleOrNull();
        },
        tag: 'ProductionDao.getLastCompletedBatch',
      );

  /// Retorna o lote atualmente ativo com seu respectivo produto
  Future<Result<ProductionBatchModel?>> getActiveBatch() => Result.catchInAsync(
    fn: () async {
      final query = select(productionBatchesTable).join([
        innerJoin(
          productsTable,
          productsTable.id.equalsExp(productionBatchesTable.productId),
        ),
      ])..where(productionBatchesTable.finishedAt.isNull());

      final row = await query.getSingleOrNull();
      if (row == null) {
        return null;
      }

      final batch = row.readTable(productionBatchesTable);
      final product = row.readTable(productsTable);

      return ProductionBatchModel(
        id: batch.id,
        product: ProductModel(
          id: product.id,
          name: product.name,
          unitWeightGrams: product.unitWeightGrams.round(),
        ),
        initialQuantity: batch.initialHardwareCount,
        actualQuantity: batch.finalHardwareCount ?? batch.initialHardwareCount,
        startedAt: batch.startedAt,
        finishedAt: batch.finishedAt,
      );
    },
    tag: 'ProductionDao.getActiveBatch',
  );

  /// Stream reativo para observar o lote ativo
  Stream<ProductionBatchModel?> watchActiveBatch() {
    final query = select(productionBatchesTable).join([
      innerJoin(
        productsTable,
        productsTable.id.equalsExp(productionBatchesTable.productId),
      ),
    ])..where(productionBatchesTable.finishedAt.isNull());

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      final batch = row.readTable(productionBatchesTable);
      final product = row.readTable(productsTable);

      return ProductionBatchModel(
        id: batch.id,
        product: ProductModel(
          id: product.id,
          name: product.name,
          unitWeightGrams: product.unitWeightGrams.round(),
        ),
        initialQuantity: batch.initialHardwareCount,
        actualQuantity: batch.finalHardwareCount ?? batch.initialHardwareCount,
        startedAt: batch.startedAt,
        finishedAt: batch.finishedAt,
      );
    });
  }

  /// Atualiza o progresso em segundo plano (finalHardwareCount parcial) do lote ativo
  Future<Result<Unit>> updateBatchProgress({
    required String batchId,
    required int actualHardwareCount,
  }) => Result.catchInAsync(
    fn: () async {
      await (update(
        productionBatchesTable,
      )..where((b) => b.id.equals(batchId))).write(
        ProductionBatchesTableCompanion(
          finalHardwareCount: Value(actualHardwareCount),
        ),
      );
      return unit;
    },
    tag: 'ProductionDao.updateBatchProgress',
  );

  /// Fecha manualmente o lote ativo
  Future<Result<Unit>> closeBatch({
    required ProductionBatchModel batch,
    DateTime? finishedAt,
  }) => Result.catchInAsync(
    fn: () async {
      await (update(
        productionBatchesTable,
      )..where((b) => b.id.equals(batch.id))).write(
        ProductionBatchesTableCompanion(
          finalHardwareCount: Value(batch.actualQuantity),
          finishedAt: Value(finishedAt ?? DateTime.now()),
          syncStatus: const Value(SyncStatusEnum.updating),
        ),
      );
      return unit;
    },
    tag: 'ProductionDao.closeBatch',
  );

  /// Finaliza automaticamente lotes que foram deixados abertos em dias anteriores à virada de meia-noite (00:00).
  /// Encerra com a contagem do último pulso registrado até 23:59:59 daquele dia.
  Future<Result<int>> autoCloseExpiredBatches({DateTime? referenceTime}) =>
      Result.catchInAsync(
        fn: () async {
          final now = referenceTime ?? DateTime.now();
          final startOfToday = DateTime(now.year, now.month, now.day);

          // Lotes abertos com data de início anterior ao início do dia de referência
          final expiredBatches = await (select(productionBatchesTable)..where(
            (b) =>
                b.finishedAt.isNull() &
                b.startedAt.isSmallerThanValue(startOfToday),
          )).get();

          if (expiredBatches.isEmpty) {
            return 0;
          }

          int closedCount = 0;
          for (final batch in expiredBatches) {
            // Busca o último pulso registrado na timeline para este lote
            final lastHit = await (select(productionTimeLinesTable)
                  ..where((t) => t.batchId.equals(batch.id))
                  ..orderBy([
                    (t) => OrderingTerm(
                      expression: t.recordedAt,
                      mode: OrderingMode.desc,
                    ),
                  ])
                  ..limit(1))
                .getSingleOrNull();

            final endOfBatchDay = DateTime(
              batch.startedAt.year,
              batch.startedAt.month,
              batch.startedAt.day,
              23,
              59,
              59,
              999,
            );

            final finalCount =
                lastHit?.currentHardwareCount ??
                batch.finalHardwareCount ??
                batch.initialHardwareCount;

            final finishedTimestamp =
                (lastHit != null && lastHit.recordedAt.isBefore(endOfBatchDay))
                    ? lastHit.recordedAt
                    : endOfBatchDay;

            await (update(
              productionBatchesTable,
            )..where((b) => b.id.equals(batch.id))).write(
              ProductionBatchesTableCompanion(
                finalHardwareCount: Value(finalCount),
                finishedAt: Value(finishedTimestamp),
                syncStatus: const Value(SyncStatusEnum.updating),
              ),
            );

            closedCount++;
          }

          return closedCount;
        },
        tag: 'ProductionDao.autoCloseExpiredBatches',
      );

  /// Obtém a contabilidade consolidada de ovos do dia especificado (padrão: hoje):
  /// - grossCount: Total bruto contado pelo hardware no dia
  /// - discardsCount: Total de quebras e descartes no dia
  /// - netCount: Total líquido (grossCount - discardsCount)
  /// - completedBoxes: Caixas fechadas computadas
  Future<Result<DailyProductionAccountingModel>> getDailyAccounting({
    DateTime? date,
  }) => Result.catchInAsync(
    fn: () async {
      final targetDate = date ?? DateTime.now();
      final startOfDay = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );
      final endOfDay = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        23,
        59,
        59,
        999,
      );

      // 1. Busca todos os lotes que rodaram no dia com seus produtos
      final batchesQuery = select(productionBatchesTable).join([
        innerJoin(
          productsTable,
          productsTable.id.equalsExp(productionBatchesTable.productId),
        ),
      ])..where(
        productionBatchesTable.startedAt.isBiggerOrEqualValue(startOfDay) &
            productionBatchesTable.startedAt.isSmallerOrEqualValue(endOfDay),
      );

      final batchRows = await batchesQuery.get();

      int dailyGrossCount = 0;
      int completedBoxes = 0;
      final List<String> batchIds = [];

      for (final row in batchRows) {
        final b = row.readTable(productionBatchesTable);
        final p = row.readTable(productsTable);
        batchIds.add(b.id);

        final endCount = b.finalHardwareCount ?? b.initialHardwareCount;
        final batchGross = (endCount - b.initialHardwareCount).clamp(
          0,
          99999999,
        );
        dailyGrossCount += batchGross;

        final boxCap = p.unitWeightGrams >= 500 ? 40 : 50;
        completedBoxes += (batchGross ~/ boxCap);
      }

      // 2. Busca todos os descartes/quebras do dia
      int dailyDiscards = 0;
      if (batchIds.isNotEmpty) {
        final adjustments = await (select(batchAdjustmentsTable)..where(
          (a) =>
              a.batchId.isIn(batchIds) |
              (a.createdAt.isBiggerOrEqualValue(startOfDay) &
                  a.createdAt.isSmallerOrEqualValue(endOfDay)),
        )).get();

        for (final adj in adjustments) {
          dailyDiscards += adj.deltaQty.abs();
        }
      }

      final netCount = (dailyGrossCount - dailyDiscards).clamp(0, 99999999);

      return DailyProductionAccountingModel(
        date: targetDate,
        grossCount: dailyGrossCount,
        discardsCount: dailyDiscards,
        netCount: netCount,
        completedBoxes: completedBoxes,
      );
    },
    tag: 'ProductionDao.getDailyAccounting',
  );

  /// Registra múltiplos pulsos de timeline em lote (Batch insert) para máxima performance sem engargalar o SQLite
  Future<Result<Unit>> batchLogTimelineHits(
    List<({String batchId, int hardwareCount, DateTime timestamp})> hits,
  ) => Result.catchInAsync(
    fn: () async {
      if (hits.isEmpty) return unit;

      await batch((batchOp) {
        batchOp.insertAll(
          productionTimeLinesTable,
          hits.map(
            (h) => ProductionTimeLinesTableCompanion.insert(
              id: GeneratorId.getid(),
              batchId: h.batchId,
              currentHardwareCount: h.hardwareCount,
              recordedAt: Value(h.timestamp),
            ),
          ),
        );
      });
      return unit;
    },
    tag: 'ProductionDao.batchLogTimelineHits',
  );

  /// Registra um único pulso na timeline (usado quando não estiver em buffer)
  Future<Result<Unit>> logTimelineHit({
    required String batchId,
    required int currentHardwareCount,
    DateTime? timestamp,
  }) => Result.catchInAsync(
    fn: () async {
      await into(productionTimeLinesTable).insert(
        ProductionTimeLinesTableCompanion.insert(
          id: GeneratorId.getid(),
          batchId: batchId,
          currentHardwareCount: currentHardwareCount,
          recordedAt: Value(timestamp ?? DateTime.now()),
        ),
      );
      return unit;
    },
    tag: 'ProductionDao.logTimelineHit',
  );

  /// Registra um ajuste / descarte / quebra em um lote
  Future<Result<Unit>> addAdjustment({
    required String batchId,
    required int deltaQty,
    required AdjustmentReasonEnum reason,
    String? observation,
  }) => Result.catchInAsync(
    fn: () async {
      await into(batchAdjustmentsTable).insert(
        BatchAdjustmentsTableCompanion.insert(
          id: GeneratorId.getid(),
          batchId: batchId,
          deltaQty: deltaQty,
          reason: reason,
          observation: Value(observation),
        ),
      );
      return unit;
    },
    tag: 'ProductionDao.addAdjustment',
  );

  /// Observa o total de ajustes de um lote
  Stream<int> watchTotalAdjustments(String batchId) {
    final query = select(batchAdjustmentsTable)
      ..where((a) => a.batchId.equals(batchId));
    return query.watch().map((adjustments) {
      return adjustments.fold(0, (sum, adj) => sum + adj.deltaQty);
    });
  }
}
