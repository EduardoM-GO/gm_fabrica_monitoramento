import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/base_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/production_batches_table.dart';

@DataClassName('BatchAdjustment')
class BatchAdjustmentsTable extends BaseTable {
  TextColumn get batchId => text().references(ProductionBatchesTable, #id)();
  IntColumn get deltaQty => integer()();
  IntColumn get reason => intEnum<AdjustmentReasonEnum>()();
  TextColumn get observation => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
