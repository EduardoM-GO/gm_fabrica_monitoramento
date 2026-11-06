import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../domain/repositories/i_sync_repository.dart';
import '../local/app_database.dart';
import '../local/daos/sync_dao.dart';
import 'supabase_client_provider.dart';

class SupabaseSyncService implements ISyncRepository {
  final SyncDao syncDao;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;

  SupabaseSyncService({required this.syncDao}) {
    // Sincronização periódica a cada 30 segundos
    _periodicSyncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => processSyncQueue(),
    );
  }

  @override
  Future<void> enqueueSync({
    required String targetTable,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await syncDao.enqueue(
      SyncQueueTableCompanion.insert(
        targetTable: targetTable,
        recordId: recordId,
        operation: operation,
        payloadJson: jsonEncode(payload),
        queuedAt: DateTime.now(),
      ),
    );

    // Tenta sincronizar imediatamente se Supabase estiver ativo
    if (SupabaseClientProvider.isInitialized) {
      unawaited(processSyncQueue());
    }
  }

  @override
  Future<int> processSyncQueue() async {
    if (_isSyncing) return 0;
    final client = SupabaseClientProvider.client;
    if (client == null) {
      // Supabase não configurado ou offline; itens continuam na fila local com segurança
      return 0;
    }

    _isSyncing = true;
    int syncedCount = 0;

    try {
      final pending = await syncDao.getPendingItems(limit: 50);
      for (final item in pending) {
        try {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;

          if (item.operation == 'INSERT' || item.operation == 'UPDATE') {
            await client.from(item.targetTable).upsert(payload);
          } else if (item.operation == 'DELETE') {
            await client.from(item.targetTable).delete().eq('id', item.recordId);
          }

          // Removido da fila local após sucesso de sincronização com a nuvem
          await syncDao.remove(item.id);
          syncedCount++;
        } catch (e) {
          debugPrint('Falha ao sincronizar item ${item.id} para ${item.targetTable}: $e');
          await syncDao.recordFailure(item.id, e.toString());
          // Em caso de falha de conexão de rede, encerra o ciclo atual para tentar no próximo intervalo
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }

    return syncedCount;
  }

  @override
  Stream<int> watchPendingCount() => syncDao.watchPendingCount();

  void dispose() {
    _periodicSyncTimer?.cancel();
  }
}
