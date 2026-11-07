import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/base_table.dart';

@DataClassName('Freezer')
class FreezersTable extends BaseTable {
  IntColumn get idSensor => integer()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
}
