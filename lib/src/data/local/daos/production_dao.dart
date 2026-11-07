import 'package:drift/drift.dart';
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
  final GeneratorId _generatorId;
  ProductionDao(super.db) : _generatorId = GeneratorId();

  Future<Result<String>> startBatch({
    required String productId,
    required int initialCount,
  }) => Result.catchInAsync(
    fn: () async {
      final batchId = _generatorId.getid();
      await into(productionBatchesTable).insert(
        ProductionBatchesTableCompanion.insert(
          id: batchId,
          productId: productId,
          initialHardwareCount: initialCount,
        ),
      );
      return batchId;
    },
    tag: 'ProductionDao.startBatch',
  );

  Future<Result<ProductionBatch?>> getActiveBatch() => Result.catchInAsync(
    fn: () async {
      return await (select(
        productionBatchesTable,
      )..where((b) => b.finishedAt.isNull())).getSingleOrNull();
    },
    tag: 'ProductionDao.getActiveBatch',
  );

  Future<Result<Unit>> closeBatch({
    required String batchId,
    required int finalCount,
  }) => Result.catchInAsync(
    fn: () async {
      await (update(
        productionBatchesTable,
      )..where((b) => b.id.equals(batchId))).write(
        ProductionBatchesTableCompanion(
          finalHardwareCount: Value(finalCount),
          finishedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatusEnum.updating), // Marca para sync
        ),
      );
      return unit;
    },
    tag: 'ProductionDao.closeBatch',
  );

  // ==========================================
  // OPERAÇÕES DA LINHA DO TEMPO (HITS)
  // ==========================================

  Future<Result<Unit>> logTimelineHit({
    required String batchId,
    required int hardwareCount,
  }) => Result.catchInAsync(
    fn: () async {
      await into(productionTimeLinesTable).insert(
        ProductionTimeLinesTableCompanion.insert(
          id: _generatorId.getid(),
          batchId: batchId,
          currentHardwareCount: hardwareCount,
        ),
      );

      return unit;
    },
    tag: 'ProductionDao.logTimelineHit',
  );

  // ==========================================
  // OPERAÇÕES DE ESTORNO
  // ==========================================

  Future<Result<Unit>> addAdjustment({
    required String batchId,
    required int deltaQty,
    required AdjustmentReasonEnum reason,
    String? observation,
  }) => Result.catchInAsync(
    fn: () async {
      await into(batchAdjustmentsTable).insert(
        BatchAdjustmentsTableCompanion.insert(
          id: _generatorId.getid(),
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
