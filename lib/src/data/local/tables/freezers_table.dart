import 'package:drift/drift.dart';

@DataClassName('Freezer')
final class FreezersTable extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
