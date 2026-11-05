import 'package:drift/drift.dart';
import '../app_database.dart';

part 'freezer_dao.g.dart';

@DriftAccessor(tables: [FreezerTelemetryLogsTable])
class FreezerDao extends DatabaseAccessor<AppDatabase> with _$FreezerDaoMixin {
  FreezerDao(super.db);

  Future<void> insertTelemetryLog(FreezerTelemetryLogsTableCompanion log) {
    return into(freezerTelemetryLogsTable).insert(log);
  }

  Future<List<FreezerTelemetryLogsTableData>> getRecentLogs({
    required String freezerId,
    int limit = 60,
  }) {
    return (select(freezerTelemetryLogsTable)
          ..where((t) => t.freezerId.equals(freezerId))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(limit))
        .get();
  }

  Stream<List<FreezerTelemetryLogsTableData>> watchRecentLogs({
    required String freezerId,
    int limit = 60,
  }) {
    return (select(freezerTelemetryLogsTable)
          ..where((t) => t.freezerId.equals(freezerId))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(limit))
        .watch();
  }
}

