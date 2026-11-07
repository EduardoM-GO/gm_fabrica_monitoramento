import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/base_table.dart';

@DataClassName('Product')
class ProductsTable extends BaseTable {
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get unitWeightGrams => real()();
}
