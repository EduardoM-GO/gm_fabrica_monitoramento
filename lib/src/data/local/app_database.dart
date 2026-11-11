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
    FreezersTable,
    RoomEventsTable,
  ],
  daos: [ProductionDao, FreezerDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
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
