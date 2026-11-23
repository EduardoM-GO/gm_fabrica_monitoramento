import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/base_table.dart';

@DataClassName('Product')
class ProductsTable extends BaseTable {
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get unitWeightGrams => real()();
  TextColumn get category => text().withDefault(const Constant('geral'))();
  TextColumn get eanCode => text().nullable()();
  IntColumn get defaultBoxCapacity =>
      integer().withDefault(const Constant(50))();
  IntColumn get defaultCoolingSeconds =>
      integer().withDefault(const Constant(1200))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
