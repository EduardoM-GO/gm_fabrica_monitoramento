import '../entities/freezer_telemetry_entity.dart';

abstract class IFreezerRepository {
  Future<void> recordTelemetryLog(FreezerTelemetryLogEntity log);
  Future<List<FreezerTelemetryLogEntity>> getRecentLogs({
    required String freezerId,
    int limit = 60,
  });
  Stream<List<FreezerTelemetryLogEntity>> watchRecentLogs({
    required String freezerId,
    int limit = 60,
  });
}

