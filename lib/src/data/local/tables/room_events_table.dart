import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/base_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/production_batches_table.dart';

@DataClassName('RoomEvent')
class RoomEventsTable extends BaseTable {
  TextColumn get batchId => text().references(ProductionBatchesTable, #id)();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();

  RealColumn get temperature => real()();
  RealColumn get humidity => real()();
}
