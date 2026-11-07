import 'package:drift/drift.dart';

@DataClassName('Product')
final class ProductsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get unitWeightGrams => real()();

  @override
  Set<Column> get primaryKey => {id};
}
