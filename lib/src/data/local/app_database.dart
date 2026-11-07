import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/batch_adjustments_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/freezer_events_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/production_batches_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/production_time_lines_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/products_table.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

@DriftDatabase(
  tables: [
    BatchAdjustmentsTable,
    FreezerEventsTable,
    ProductionBatchesTable,
    ProductionTimeLinesTable,
    ProductsTable,
  ],
  daos: [],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

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
