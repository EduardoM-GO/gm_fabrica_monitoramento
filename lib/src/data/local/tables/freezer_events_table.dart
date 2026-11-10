import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/trigger_freezer_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/base_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/freezers_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/production_batches_table.dart';

@DataClassName('FreezerEvent')
class FreezerEventsTable extends BaseTable {
  TextColumn get freezerId => text().references(FreezersTable, #id)();
  TextColumn get batchId => text().references(ProductionBatchesTable, #id)();

  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();

  RealColumn get temperature => real()();
  BoolColumn get isDoorOpen => boolean()();

  IntColumn get triggerReason => intEnum<TriggerFreezerEnum>()();
}
