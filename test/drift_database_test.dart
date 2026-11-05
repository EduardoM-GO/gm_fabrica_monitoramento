import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/data/datasources/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Drift Seed: produtos padrão de Páscoa são pré-cadastrados na inicialização', () async {
    final products = await db.productionDao.getActiveProducts();
    expect(products.length, greaterThanOrEqualTo(3));
    expect(products.any((p) => p.id == 'prod_ovo_250'), isTrue);
    expect(products.any((p) => p.id == 'prod_casca_500'), isTrue);
    expect(products.any((p) => p.id == 'prod_mini_100'), isTrue);
  });

  test('Ciclo de vida do Lote no Drift e Auditoria de Ajustes', () async {
    // 1. Cria lote
    await db.productionDao.insertBatch(
      ProductionBatchesTableCompanion.insert(
        id: 'batch_001',
        productId: 'prod_ovo_250',
        startedAt: DateTime.now(),
        initialHardwareCount: 0,
        grossProducedCount: const Value(50),
        discardedCount: const Value(0),
        status: 'inProgress',
      ),
    );

    var active = await db.productionDao.getActiveBatch();
    expect(active, isNotNull);
    expect(active!.id, equals('batch_001'));
    expect(active.grossProducedCount, equals(50));

    // 2. Registra ajuste / descarte
    await db.productionDao.insertAdjustment(
      BatchAdjustmentsTableCompanion.insert(
        id: 'adj_001',
        batchId: 'batch_001',
        reason: 'brokenShell',
        customNote: const Value('Casca trincada no desmolde'),
        deltaQuantity: -2,
        createdAt: DateTime.now(),
      ),
    );
    await db.productionDao.incrementDiscardedCount('batch_001', 2);

    active = await db.productionDao.getActiveBatch();
    expect(active!.discardedCount, equals(2));

    // 3. Auditoria de ajustes
    final adjustments = await db.productionDao.getAdjustmentsForBatch('batch_001');
    expect(adjustments.length, equals(1));
    expect(adjustments.first.reason, equals('brokenShell'));
    expect(adjustments.first.customNote, equals('Casca trincada no desmolde'));
  });

  test('Outbox SyncQueue: enfileiramento e remoção FIFO', () async {
    await db.syncDao.enqueue(
      SyncQueueTableCompanion.insert(
        targetTable: 'production_batches',
        recordId: 'batch_001',
        operation: 'INSERT',
        payloadJson: '{"id": "batch_001"}',
        queuedAt: DateTime.now(),
      ),
    );

    final pending = await db.syncDao.getPendingItems();
    expect(pending.length, equals(1));
    expect(pending.first.recordId, equals('batch_001'));

    await db.syncDao.remove(pending.first.id);
    final afterRemove = await db.syncDao.getPendingItems();
    expect(afterRemove.isEmpty, isTrue);
  });
}
