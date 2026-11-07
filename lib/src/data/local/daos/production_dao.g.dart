// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_dao.dart';

// ignore_for_file: type=lint
mixin _$ProductionDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductionBatchesTableTable get productionBatchesTable =>
      attachedDatabase.productionBatchesTable;
  $BatchAdjustmentsTableTable get batchAdjustmentsTable =>
      attachedDatabase.batchAdjustmentsTable;
  $ProductionTimeLinesTableTable get productionTimeLinesTable =>
      attachedDatabase.productionTimeLinesTable;
  ProductionDaoManager get managers => ProductionDaoManager(this);
}

class ProductionDaoManager {
  final _$ProductionDaoMixin _db;
  ProductionDaoManager(this._db);
  $$ProductionBatchesTableTableTableManager get productionBatchesTable =>
      $$ProductionBatchesTableTableTableManager(
        _db.attachedDatabase,
        _db.productionBatchesTable,
      );
  $$BatchAdjustmentsTableTableTableManager get batchAdjustmentsTable =>
      $$BatchAdjustmentsTableTableTableManager(
        _db.attachedDatabase,
        _db.batchAdjustmentsTable,
      );
  $$ProductionTimeLinesTableTableTableManager get productionTimeLinesTable =>
      $$ProductionTimeLinesTableTableTableManager(
        _db.attachedDatabase,
        _db.productionTimeLinesTable,
      );
}
