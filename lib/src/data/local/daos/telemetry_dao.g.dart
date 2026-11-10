// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemetry_dao.dart';

// ignore_for_file: type=lint
mixin _$TelemetryDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductionTimeLinesTableTable get productionTimeLinesTable =>
      attachedDatabase.productionTimeLinesTable;
  $FreezerEventsTableTable get freezerEventsTable =>
      attachedDatabase.freezerEventsTable;
  $RoomEventsTableTable get roomEventsTable => attachedDatabase.roomEventsTable;
  TelemetryDaoManager get managers => TelemetryDaoManager(this);
}

class TelemetryDaoManager {
  final _$TelemetryDaoMixin _db;
  TelemetryDaoManager(this._db);
  $$ProductionTimeLinesTableTableTableManager get productionTimeLinesTable =>
      $$ProductionTimeLinesTableTableTableManager(
        _db.attachedDatabase,
        _db.productionTimeLinesTable,
      );
  $$FreezerEventsTableTableTableManager get freezerEventsTable =>
      $$FreezerEventsTableTableTableManager(
        _db.attachedDatabase,
        _db.freezerEventsTable,
      );
  $$RoomEventsTableTableTableManager get roomEventsTable =>
      $$RoomEventsTableTableTableManager(
        _db.attachedDatabase,
        _db.roomEventsTable,
      );
}
