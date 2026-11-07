import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/sync_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/production_batches_table.dart';

@DataClassName('BatchAdjustment')
final class BatchAdjustmentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get batchId => text().references(ProductionBatchesTable, #id)();
  IntColumn get deltaQty => integer()();
  IntColumn get reason => intEnum<AdjustmentReasonEnum>()();
  TextColumn get observation => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  IntColumn get syncStatus =>
      intEnum<SyncStatusEnum>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
