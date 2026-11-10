import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/app_database.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/freezer_events_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/production_time_lines_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/room_events_table.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/telemetry_model.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';

part 'telemetry_dao.g.dart';

@DriftAccessor(
  tables: [ProductionTimeLinesTable, FreezerEventsTable, RoomEventsTable],
)
class TelemetryDao extends DatabaseAccessor<AppDatabase>
    with _$TelemetryDaoMixin {
  TelemetryDao(super.db);

  Future<Result<Unit>> register({required TelemetryModel telemetry}) =>
      Result.catchInAsync(
        fn: () async => transaction(() async {
          await into(productionTimeLinesTable).insert(
            ProductionTimeLinesTableCompanion.insert(
              id: telemetry.id,
              batchId: telemetry.batch.id,
              currentHardwareCount: telemetry.batch.actualQuantity,
            ),
          );

          for (final event in telemetry.freezerEvents) {
            await into(freezerEventsTable).insert(
              FreezerEventsTableCompanion.insert(
                id: event.id,
                freezerId: event.freezer.id,
                batchId: event.batch.id,
                temperature: event.temperature,
                isDoorOpen: event.isDoorOpen,
                triggerReason: event.triggerReason,
              ),
            );
          }

          final room = telemetry.room;

          if (room != null) {
            await into(roomEventsTable).insert(
              RoomEventsTableCompanion.insert(
                id: room.id,
                batchId: room.batch.id,
                humidity: room.humidity,
                temperature: room.temperature,
              ),
            );
          }

          return unit;
        }),
        tag: 'TelemetryDao-register',
      );
}
