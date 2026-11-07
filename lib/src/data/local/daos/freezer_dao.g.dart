// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'freezer_dao.dart';

// ignore_for_file: type=lint
mixin _$FreezerDaoMixin on DatabaseAccessor<AppDatabase> {
  $FreezerEventsTableTable get freezerEventsTable =>
      attachedDatabase.freezerEventsTable;
  $CoolingCyclesTableTable get coolingCyclesTable =>
      attachedDatabase.coolingCyclesTable;
  $FreezersTableTable get freezersTable => attachedDatabase.freezersTable;
  FreezerDaoManager get managers => FreezerDaoManager(this);
}

class FreezerDaoManager {
  final _$FreezerDaoMixin _db;
  FreezerDaoManager(this._db);
  $$FreezerEventsTableTableTableManager get freezerEventsTable =>
      $$FreezerEventsTableTableTableManager(
        _db.attachedDatabase,
        _db.freezerEventsTable,
      );
  $$CoolingCyclesTableTableTableManager get coolingCyclesTable =>
      $$CoolingCyclesTableTableTableManager(
        _db.attachedDatabase,
        _db.coolingCyclesTable,
      );
  $$FreezersTableTableTableManager get freezersTable =>
      $$FreezersTableTableTableManager(_db.attachedDatabase, _db.freezersTable);
}
