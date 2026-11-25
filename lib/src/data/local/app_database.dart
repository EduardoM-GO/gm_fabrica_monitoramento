import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/daos/freezer_dao.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/daos/production_dao.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/sync_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/trigger_freezer_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/batch_adjustments_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/cooling_cycles_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/freezer_calibrations_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/freezer_events_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/freezers_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/production_batches_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/production_time_lines_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/products_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/room_events_table.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    BatchAdjustmentsTable,
    FreezerEventsTable,
    ProductionBatchesTable,
    ProductionTimeLinesTable,
    ProductsTable,
    CoolingCyclesTable,
    FreezerCalibrationsTable,
    FreezersTable,
    RoomEventsTable,
  ],
  daos: [ProductionDao, FreezerDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(productsTable, productsTable.category);
          await m.addColumn(productsTable, productsTable.eanCode);
          await m.addColumn(productsTable, productsTable.defaultBoxCapacity);
          await m.addColumn(productsTable, productsTable.defaultCoolingSeconds);
          await m.addColumn(productsTable, productsTable.isActive);

          await m.addColumn(freezersTable, freezersTable.equipmentId);
          await m.addColumn(freezersTable, freezersTable.equipmentName);
          await m.addColumn(freezersTable, freezersTable.targetTemperature);
          await m.addColumn(freezersTable, freezersTable.defaultCoolingSeconds);
          await m.addColumn(freezersTable, freezersTable.unloadMinSeconds);
          await m.addColumn(freezersTable, freezersTable.reloadMinSeconds);

          // Remove produtos mockados antigos caso não possuam lotes vinculados
          await customStatement(
            "DELETE FROM products_table WHERE id IN ('prod_ovo_250', 'prod_casca_500', 'prod_mini_100') "
            "AND id NOT IN (SELECT DISTINCT product_id FROM production_batches_table)",
          );
        }
        if (from < 3) {
          await m.addColumn(
            coolingCyclesTable,
            coolingCyclesTable.accumulatedDefrostSeconds,
          );
          // ignore: experimental_member_use
          await m.alterTable(TableMigration(freezerEventsTable));
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gm_fabrica_edge.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
