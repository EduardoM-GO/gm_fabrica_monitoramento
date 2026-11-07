import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/base_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/products_table.dart';

@DataClassName('ProductionBatch')
class ProductionBatchesTable extends BaseTable {
  TextColumn get productId => text().references(ProductsTable, #id)();

  IntColumn get initialHardwareCount => integer()();
  IntColumn get finalHardwareCount => integer().nullable()();

  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get finishedAt => dateTime().nullable()();
}
