import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/freezer_dao.dart';
import 'daos/production_dao.dart';
import 'daos/sync_dao.dart';

part 'app_database.g.dart';

// --- Tabelas ---

class ProductsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get unitWeightGrams => real()();
  IntColumn get defaultBoxCapacity =>
      integer().withDefault(const Constant(50))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class ProductionBatchesTable extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(ProductsTable, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  IntColumn get initialHardwareCount => integer()();
  IntColumn get grossProducedCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get discardedCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text()(); // 'inProgress', 'paused', 'completed'
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class BatchAdjustmentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get batchId => text().references(ProductionBatchesTable, #id)();
  TextColumn get reason => text()();
  TextColumn get customNote => text().nullable()();
  IntColumn get deltaQuantity => integer()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class FreezerTelemetryLogsTable extends Table {
  TextColumn get id => text()();
  TextColumn get freezerId => text()();
  RealColumn get temperature => real()();
  BoolColumn get isDoorOpen => boolean()();
  BoolColumn get isSensorOk => boolean()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get triggerReason => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable =>
      text()(); // 'production_batches', 'batch_adjustments', etc.
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // 'INSERT', 'UPDATE', 'DELETE'
  TextColumn get payloadJson => text()();
  DateTimeColumn get queuedAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

@DriftDatabase(
  tables: [
    ProductsTable,
    ProductionBatchesTable,
    BatchAdjustmentsTable,
    FreezerTelemetryLogsTable,
    SyncQueueTable,
  ],
  daos: [
    ProductionDao,
    FreezerDao,
    SyncDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'gm_fabrica_offline_db',
      native: const DriftNativeOptions(
        shareAcrossIsolates: true,
      ),
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Carga inicial com produtos da fábrica
          await into(productsTable).insert(
            ProductsTableCompanion.insert(
              id: 'prod_ovo_250',
              name: 'Ovo Tradicional 250g',
              unitWeightGrams: 250.0,
              defaultBoxCapacity: const Value(50),
            ),
          );
          await into(productsTable).insert(
            ProductsTableCompanion.insert(
              id: 'prod_casca_500',
              name: 'Casca Recheada 500g',
              unitWeightGrams: 500.0,
              defaultBoxCapacity: const Value(40),
            ),
          );
          await into(productsTable).insert(
            ProductsTableCompanion.insert(
              id: 'prod_mini_100',
              name: 'Mini Ovo Gourmet 100g',
              unitWeightGrams: 100.0,
              defaultBoxCapacity: const Value(50),
            ),
          );
        },
      );
}
