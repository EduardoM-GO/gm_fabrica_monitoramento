import 'package:drift/drift.dart';
import '../../../domain/entities/freezer_telemetry_entity.dart';
import '../../../domain/repositories/i_freezer_repository.dart';
import '../../../domain/repositories/i_sync_repository.dart';
import '../datasources/local/app_database.dart';
import '../datasources/local/daos/freezer_dao.dart';

class FreezerRepositoryImpl implements IFreezerRepository {
  final FreezerDao dao;
  final ISyncRepository syncRepo;

  FreezerRepositoryImpl({
    required this.dao,
    required this.syncRepo,
  });

  @override
  Future<void> recordTelemetryLog(FreezerTelemetryLogEntity log) async {
    await dao.insertTelemetryLog(
      FreezerTelemetryLogsTableCompanion.insert(
        id: log.id,
        freezerId: log.freezerId,
        temperature: log.temperature,
        isDoorOpen: log.isDoorOpen,
        isSensorOk: log.isSensorOk,
        recordedAt: log.recordedAt,
        triggerReason: Value(log.triggerReason),
        synced: const Value(false),
      ),
    );

    // Enfileira telemetria amostrada para sincronização remota
    await syncRepo.enqueueSync(
      targetTable: 'freezer_telemetry_logs',
      recordId: log.id,
      operation: 'INSERT',
      payload: {
        'id': log.id,
        'freezer_id': log.freezerId,
        'temperature': log.temperature,
        'is_door_open': log.isDoorOpen,
        'is_sensor_ok': log.isSensorOk,
        'recorded_at': log.recordedAt.toIso8601String(),
        'trigger_reason': log.triggerReason,
      },
    );
  }

  @override
  Future<List<FreezerTelemetryLogEntity>> getRecentLogs({
    required String freezerId,
    int limit = 60,
  }) async {
    final rows = await dao.getRecentLogs(freezerId: freezerId, limit: limit);
    return rows
        .map((r) => FreezerTelemetryLogEntity(
              id: r.id,
              freezerId: r.freezerId,
              temperature: r.temperature,
              isDoorOpen: r.isDoorOpen,
              isSensorOk: r.isSensorOk,
              recordedAt: r.recordedAt,
              triggerReason: r.triggerReason,
              isSynced: r.synced,
            ))
        .toList();
  }

  @override
  Stream<List<FreezerTelemetryLogEntity>> watchRecentLogs({
    required String freezerId,
    int limit = 60,
  }) {
    return dao.watchRecentLogs(freezerId: freezerId, limit: limit).map(
          (rows) => rows
              .map((r) => FreezerTelemetryLogEntity(
                    id: r.id,
                    freezerId: r.freezerId,
                    temperature: r.temperature,
                    isDoorOpen: r.isDoorOpen,
                    isSensorOk: r.isSensorOk,
                    recordedAt: r.recordedAt,
                    triggerReason: r.triggerReason,
                    isSynced: r.synced,
                  ))
              .toList(),
        );
  }
}
