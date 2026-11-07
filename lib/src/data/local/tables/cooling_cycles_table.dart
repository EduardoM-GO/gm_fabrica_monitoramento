import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/base_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/production_batches_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/freezers_table.dart';

@DataClassName('CoolingCycle')
class CoolingCyclesTable extends BaseTable {
  TextColumn get batchId => text().references(ProductionBatchesTable, #id)();
  TextColumn get freezerId => text().references(FreezersTable, #id)();

  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  IntColumn get expectedDurationSeconds => integer()();
  IntColumn get actualDurationSeconds => integer().nullable()();

  // Penalidade de porta aberta durante o ciclo
  IntColumn get accumulatedDoorOpenSeconds =>
      integer().withDefault(const Constant(0))();
}
