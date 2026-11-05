import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/batch_adjustment_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/production_batch_entity.dart';
import '../../../domain/repositories/i_production_repository.dart';
import '../../../domain/repositories/i_sync_repository.dart';
import '../datasources/local/app_database.dart';
import '../datasources/local/daos/production_dao.dart';

class ProductionRepositoryImpl implements IProductionRepository {
  final ProductionDao dao;
  final ISyncRepository syncRepo;
  final _uuid = const Uuid();

  ProductionRepositoryImpl({
    required this.dao,
    required this.syncRepo,
  });

  @override
  Future<List<ProductEntity>> getActiveProducts() async {
    final rows = await dao.getActiveProducts();
    return rows
        .map((r) => ProductEntity(
              id: r.id,
              name: r.name,
              unitWeightGrams: r.unitWeightGrams,
              defaultBoxCapacity: r.defaultBoxCapacity,
              isActive: r.isActive,
            ))
        .toList();
  }

  @override
  Future<ProductEntity?> getProductById(String id) async {
    final r = await dao.getProductById(id);
    if (r == null) return null;
    return ProductEntity(
      id: r.id,
      name: r.name,
      unitWeightGrams: r.unitWeightGrams,
      defaultBoxCapacity: r.defaultBoxCapacity,
      isActive: r.isActive,
    );
  }

  @override
  Future<ProductionBatchEntity?> getActiveBatch() async {
    final r = await dao.getActiveBatch();
    if (r == null) return null;
    final product = await getProductById(r.productId);
    return _mapBatch(r, product);
  }

  @override
  Stream<ProductionBatchEntity?> watchActiveBatch() {
    return dao.watchActiveBatch().asyncMap((r) async {
      if (r == null) return null;
      final product = await getProductById(r.productId);
      return _mapBatch(r, product);
    });
  }

  @override
  Future<void> startBatch({
    required String productId,
    required int initialHardwareCount,
  }) async {
    final product = await getProductById(productId);
    if (product == null) {
      throw ArgumentError('Produto não encontrado: $productId');
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    await dao.insertBatch(
      ProductionBatchesTableCompanion.insert(
        id: id,
        productId: productId,
        startedAt: now,
        initialHardwareCount: initialHardwareCount,
        grossProducedCount: const Value(0),
        discardedCount: const Value(0),
        status: BatchStatus.inProgress.name,
        synced: const Value(false),
      ),
    );

    await syncRepo.enqueueSync(
      targetTable: 'production_batches',
      recordId: id,
      operation: 'INSERT',
      payload: {
        'id': id,
        'product_id': productId,
        'started_at': now.toIso8601String(),
        'initial_hardware_count': initialHardwareCount,
        'gross_produced_count': 0,
        'discarded_count': 0,
        'status': BatchStatus.inProgress.name,
      },
    );
  }

  @override
  Future<void> updateBatchProgress({
    required String batchId,
    required int grossProducedCount,
  }) async {
    await dao.updateBatchProgress(batchId, grossProducedCount);
  }

  @override
  Future<void> pauseBatch(String batchId) async {
    await dao.updateBatchStatus(batchId, BatchStatus.paused.name);
    await syncRepo.enqueueSync(
      targetTable: 'production_batches',
      recordId: batchId,
      operation: 'UPDATE',
      payload: {
        'id': batchId,
        'status': BatchStatus.paused.name,
      },
    );
  }

  @override
  Future<void> resumeBatch(String batchId) async {
    await dao.updateBatchStatus(batchId, BatchStatus.inProgress.name);
    await syncRepo.enqueueSync(
      targetTable: 'production_batches',
      recordId: batchId,
      operation: 'UPDATE',
      payload: {
        'id': batchId,
        'status': BatchStatus.inProgress.name,
      },
    );
  }

  @override
  Future<void> finishBatch(String batchId) async {
    final now = DateTime.now();
    await dao.updateBatchStatus(batchId, BatchStatus.completed.name, finishedAt: now);
    await syncRepo.enqueueSync(
      targetTable: 'production_batches',
      recordId: batchId,
      operation: 'UPDATE',
      payload: {
        'id': batchId,
        'status': BatchStatus.completed.name,
        'finished_at': now.toIso8601String(),
      },
    );
  }

  @override
  Future<void> addAdjustment({
    required String batchId,
    required AdjustmentReason reason,
    required int deltaQuantity,
    String? customNote,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await dao.insertAdjustment(
      BatchAdjustmentsTableCompanion.insert(
        id: id,
        batchId: batchId,
        reason: reason.name,
        customNote: Value(customNote),
        deltaQuantity: deltaQuantity,
        createdAt: now,
        synced: const Value(false),
      ),
    );

    // Incrementa contagem de descartes no lote
    await dao.incrementDiscardedCount(batchId, deltaQuantity.abs());

    await syncRepo.enqueueSync(
      targetTable: 'batch_adjustments',
      recordId: id,
      operation: 'INSERT',
      payload: {
        'id': id,
        'batch_id': batchId,
        'reason': reason.name,
        'custom_note': customNote,
        'delta_quantity': deltaQuantity,
        'created_at': now.toIso8601String(),
      },
    );
  }

  @override
  Future<List<BatchAdjustmentEntity>> getAdjustmentsForBatch(String batchId) async {
    final rows = await dao.getAdjustmentsForBatch(batchId);
    return rows
        .map((r) => BatchAdjustmentEntity(
              id: r.id,
              batchId: r.batchId,
              reason: AdjustmentReason.fromString(r.reason),
              customNote: r.customNote,
              deltaQuantity: r.deltaQuantity,
              createdAt: r.createdAt,
              isSynced: r.synced,
            ))
        .toList();
  }

  ProductionBatchEntity _mapBatch(
    ProductionBatchesTableData r,
    ProductEntity? product,
  ) {
    final status = BatchStatus.values.firstWhere(
      (e) => e.name == r.status,
      orElse: () => BatchStatus.inProgress,
    );

    return ProductionBatchEntity(
      id: r.id,
      productId: r.productId,
      productName: product?.name ?? 'Produto ${r.productId}',
      unitWeightGrams: product?.unitWeightGrams ?? 250.0,
      startedAt: r.startedAt,
      finishedAt: r.finishedAt,
      initialHardwareCount: r.initialHardwareCount,
      grossProducedCount: r.grossProducedCount,
      discardedCount: r.discardedCount,
      status: status,
      isSynced: r.synced,
    );
  }
}
