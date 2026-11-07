import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/sync_status_enum.dart';

class BaseTable extends Table {
  TextColumn get id => text()();

  IntColumn get syncStatus =>
      intEnum<SyncStatusEnum>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
