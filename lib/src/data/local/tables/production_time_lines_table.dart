import 'package:drift/drift.dart';

import 'package:gm_fabrica_monitoramento/src/data/local/enum/sync_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/production_batches_table.dart';

@DataClassName('ProductionTimeline')
final class ProductionTimeLinesTable extends Table {
  TextColumn get id => text()(); // UUID

  TextColumn get batchId => text().references(ProductionBatchesTable, #id)();

  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();

  IntColumn get currentHardwareCount => integer()();

  IntColumn get syncStatus =>
      intEnum<SyncStatusEnum>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
