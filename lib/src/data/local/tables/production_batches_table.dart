import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/sync_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/products_table.dart';

@DataClassName('ProductionBatch')
final class ProductionBatchesTable extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(ProductsTable, #id)();

  IntColumn get initialHardwareCount => integer()();
  IntColumn get finalHardwareCount => integer().nullable()();

  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  IntColumn get syncStatus =>
      intEnum<SyncStatusEnum>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
