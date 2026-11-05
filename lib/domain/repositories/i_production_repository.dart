import '../entities/batch_adjustment_entity.dart';
import '../entities/product_entity.dart';
import '../entities/production_batch_entity.dart';

abstract class IProductionRepository {
  Future<List<ProductEntity>> getActiveProducts();
  Future<ProductEntity?> getProductById(String id);
  Future<ProductionBatchEntity?> getActiveBatch();
  Future<void> startBatch({
    required String productId,
    required int initialHardwareCount,
  });
  Future<void> updateBatchProgress({
    required String batchId,
    required int grossProducedCount,
  });
  Future<void> pauseBatch(String batchId);
  Future<void> resumeBatch(String batchId);
  Future<void> finishBatch(String batchId);
  Future<void> addAdjustment({
    required String batchId,
    required AdjustmentReason reason,
    required int deltaQuantity,
    String? customNote,
  });
  Future<List<BatchAdjustmentEntity>> getAdjustmentsForBatch(String batchId);
  Stream<ProductionBatchEntity?> watchActiveBatch();
}

