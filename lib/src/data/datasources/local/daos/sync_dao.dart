import 'package:drift/drift.dart';
import '../app_database.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  Future<int> enqueue(SyncQueueTableCompanion item) {
    return into(syncQueueTable).insert(item);
  }

  Future<List<SyncQueueTableData>> getPendingItems({int limit = 50}) {
    return (select(syncQueueTable)
          ..orderBy([(t) => OrderingTerm.asc(t.queuedAt)])
          ..limit(limit))
        .get();
  }

  Future<int> remove(int id) {
    return (delete(syncQueueTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> recordFailure(int id, String error) async {
    final item = await (select(syncQueueTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (item != null) {
      await (update(syncQueueTable)..where((t) => t.id.equals(id))).write(
        SyncQueueTableCompanion(
          retryCount: Value(item.retryCount + 1),
          lastError: Value(error),
        ),
      );
    }
  }

  Stream<int> watchPendingCount() {
    final countExp = syncQueueTable.id.count();
    final query = selectOnly(syncQueueTable)..addColumns([countExp]);
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }
}

