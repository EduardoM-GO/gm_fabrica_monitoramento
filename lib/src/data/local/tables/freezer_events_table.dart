import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/sync_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/trigger_freezer_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/freezers_table.dart';

@DataClassName('FreezerEvent')
final class FreezerEventsTable extends Table {
  TextColumn get id => text()();
  IntColumn get freezerId => integer().references(FreezersTable, #id)();

  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();

  RealColumn get temperature => real()();
  BoolColumn get doorOpen => boolean()();

  IntColumn get triggerReason => intEnum<TriggerFreezerEnum>()();

  IntColumn get syncStatus =>
      intEnum<SyncStatusEnum>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
