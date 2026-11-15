import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/base_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/freezers_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/production_batches_table.dart';

@DataClassName('CoolingCycle')
class CoolingCyclesTable extends BaseTable {
  TextColumn get batchId =>
      text().nullable().references(ProductionBatchesTable, #id)();
  TextColumn get freezerId => text().references(FreezersTable, #id)();

  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  // Temperaturas registradas para cálculo da carga térmica
  RealColumn get baselineTemp => real().nullable()();
  RealColumn get initialPeakTemp => real().nullable()();

  IntColumn get expectedDurationSeconds => integer()();
  IntColumn get actualDurationSeconds => integer().nullable()();

  // Métricas de abertura de porta e penalidades acumuladas durante o ciclo
  IntColumn get accumulatedDoorOpenSeconds =>
      integer().withDefault(const Constant(0))();
  IntColumn get accumulatedPenaltySeconds =>
      integer().withDefault(const Constant(0))();
  IntColumn get doorOpenCount => integer().withDefault(const Constant(0))();

  // Feedback registrado ao final: 'on_point', 'soft', 'overchilled', 'auto_ok'
  TextColumn get feedback => text().nullable()();
}
