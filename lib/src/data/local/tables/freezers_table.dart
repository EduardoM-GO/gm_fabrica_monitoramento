import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/base_table.dart';

@DataClassName('Freezer')
class FreezersTable extends BaseTable {
  IntColumn get idSensor => integer()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();

  /// UUID do equipamento vinculado na tabela `public.cost_centers` do Supabase.
  TextColumn get equipmentId => text().nullable()();

  /// Nome do equipamento vinculado na tabela `public.cost_centers` do Supabase.
  TextColumn get equipmentName => text().nullable()();

  RealColumn get targetTemperature =>
      real().withDefault(const Constant(4.0))();
  IntColumn get defaultCoolingSeconds =>
      integer().withDefault(const Constant(480))();
  IntColumn get unloadMinSeconds =>
      integer().withDefault(const Constant(30))();
  IntColumn get reloadMinSeconds =>
      integer().withDefault(const Constant(60))();
}
