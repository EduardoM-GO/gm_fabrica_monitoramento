// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'freezer_dao.dart';

// ignore_for_file: type=lint
mixin _$FreezerDaoMixin on DatabaseAccessor<AppDatabase> {
  $FreezerTelemetryLogsTableTable get freezerTelemetryLogsTable =>
      attachedDatabase.freezerTelemetryLogsTable;
  FreezerDaoManager get managers => FreezerDaoManager(this);
}

class FreezerDaoManager {
  final _$FreezerDaoMixin _db;
  FreezerDaoManager(this._db);
  $$FreezerTelemetryLogsTableTableTableManager get freezerTelemetryLogsTable =>
      $$FreezerTelemetryLogsTableTableTableManager(
        _db.attachedDatabase,
        _db.freezerTelemetryLogsTable,
      );
}
