import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/product_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/production_batch_model.dart';
import 'package:gm_fabrica_monitoramento/src/utils/generator_id.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';

import '../app_database.dart';
import '../tables/production_batches_table.dart';
import '../tables/batch_adjustments_table.dart';
import '../tables/production_time_lines_table.dart';
import '../enum/adjustment_reason_enum.dart';
import '../enum/sync_status_enum.dart';

part 'production_dao.g.dart';

@DriftAccessor(
  tables: [
    ProductionBatchesTable,
    BatchAdjustmentsTable,
    ProductionTimeLinesTable,
  ],
)
final class ProductionDao extends DatabaseAccessor<AppDatabase>
    with _$ProductionDaoMixin {
  ProductionDao(super.db);

  Future<Result<ProductionBatchModel>> startBatch({
    required ProductModel product,
  }) => Result.catchInAsync(
    fn: () async {
      final lastBatchResult = await getLastCompletedBatch();

      if (lastBatchResult.isError) {
        throw lastBatchResult.errorOrThrow;
      }

      final lastBatch = lastBatchResult.valueOrThrow;

      final batch = ProductionBatchModel(
        product: product,
        initialQuantity: lastBatch?.finalHardwareCount ?? 0,
        actualQuantity: lastBatch?.finalHardwareCount ?? 0,
      );

      await into(productionBatchesTable).insert(
        ProductionBatchesTableCompanion.insert(
          id: batch.id,
          productId: batch.product.id,
          initialHardwareCount: batch.initialQuantity,
        ),
      );

      return batch;
    },
    tag: 'ProductionDao.startBatch',
  );

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
                ])) // Correção da query
              .getSingleOrNull();
        },
        tag: 'ProductionDao.getLastCompletedBatch',
      );

  Future<Result<ProductionBatch?>> getActiveBatch() => Result.catchInAsync(
    fn: () async {
      return await (select(
        productionBatchesTable,
      )..where((b) => b.finishedAt.isNull())).getSingleOrNull();
    },
    tag: 'ProductionDao.getActiveBatch',
  );

  Future<Result<Unit>> closeBatch({required ProductionBatchModel batch}) =>
      Result.catchInAsync(
        fn: () async {
          await (update(
            productionBatchesTable,
          )..where((b) => b.id.equals(batch.id))).write(
            ProductionBatchesTableCompanion(
              finalHardwareCount: Value(batch.actualQuantity),
              finishedAt: Value(DateTime.now()),
              syncStatus: const Value(SyncStatusEnum.updating),
            ),
          );
          return unit;
        },
        tag: 'ProductionDao.closeBatch',
      );

  Future<Result<Unit>> logTimelineHit({required ProductionBatchModel batch}) =>
      Result.catchInAsync(
        fn: () async {
          await into(productionTimeLinesTable).insert(
            ProductionTimeLinesTableCompanion.insert(
              id: GeneratorId.getid(),
              batchId: batch.id,
              currentHardwareCount: batch.actualQuantity,
            ),
          );
          return unit;
        },
        tag: 'ProductionDao.logTimelineHit',
      );

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

  Stream<int> watchTotalAdjustments(String batchId) {
    final query = select(batchAdjustmentsTable)
      ..where((a) => a.batchId.equals(batchId));
    return query.watch().map((adjustments) {
      return adjustments.fold(0, (sum, adj) => sum + adj.deltaQty);
    });
  }
}
