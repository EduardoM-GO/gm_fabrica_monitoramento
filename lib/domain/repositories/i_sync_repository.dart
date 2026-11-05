abstract class ISyncRepository {
  Future<void> enqueueSync({
    required String targetTable,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  });
  Future<int> processSyncQueue();
  Stream<int> watchPendingCount();
}

