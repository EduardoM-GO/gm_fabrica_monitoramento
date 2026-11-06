import 'package:drift/drift.dart';
import '../app_database.dart';

part 'production_dao.g.dart';

@DriftAccessor(tables: [ProductsTable, ProductionBatchesTable, BatchAdjustmentsTable])
class ProductionDao extends DatabaseAccessor<AppDatabase> with _$ProductionDaoMixin {
  ProductionDao(super.db);

  Future<List<ProductsTableData>> getActiveProducts() {
    return (select(productsTable)..where((t) => t.isActive.equals(true))).get();
  }

  Future<ProductsTableData?> getProductById(String id) {
    return (select(productsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<ProductionBatchesTableData?> getActiveBatch() {
    return (select(productionBatchesTable)
          ..where((t) => t.status.equals('inProgress') | t.status.equals('paused'))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<ProductionBatchesTableData?> watchActiveBatch() {
    return (select(productionBatchesTable)
          ..where((t) => t.status.equals('inProgress') | t.status.equals('paused'))
          ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<void> insertBatch(ProductionBatchesTableCompanion batch) {
    return into(productionBatchesTable).insert(batch);
  }

  Future<void> updateBatchProgress(String batchId, int grossCount) {
    return (update(productionBatchesTable)..where((t) => t.id.equals(batchId))).write(
      ProductionBatchesTableCompanion(
        grossProducedCount: Value(grossCount),
      ),
    );
  }

  Future<void> updateBatchStatus(String batchId, String status, {DateTime? finishedAt}) {
    return (update(productionBatchesTable)..where((t) => t.id.equals(batchId))).write(
      ProductionBatchesTableCompanion(
        status: Value(status),
        finishedAt: Value(finishedAt),
      ),
    );
  }

  Future<void> incrementDiscardedCount(String batchId, int delta) async {
    final batch = await (select(productionBatchesTable)..where((t) => t.id.equals(batchId))).getSingleOrNull();
    if (batch != null) {
      final newDiscarded = batch.discardedCount + delta;
      await (update(productionBatchesTable)..where((t) => t.id.equals(batchId))).write(
        ProductionBatchesTableCompanion(
          discardedCount: Value(newDiscarded),
        ),
      );
    }
  }

  Future<void> insertAdjustment(BatchAdjustmentsTableCompanion adj) {
    return into(batchAdjustmentsTable).insert(adj);
  }

  Future<List<BatchAdjustmentsTableData>> getAdjustmentsForBatch(String batchId) {
    return (select(batchAdjustmentsTable)
          ..where((t) => t.batchId.equals(batchId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }
}

