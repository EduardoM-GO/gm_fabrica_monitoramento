import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/base_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/freezers_table.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/tables/products_table.dart';

@DataClassName('FreezerCalibration')
class FreezerCalibrationsTable extends BaseTable {
  TextColumn get freezerId => text().references(FreezersTable, #id)();
  TextColumn get productId =>
      text().nullable().references(ProductsTable, #id)();

  // Tempo base calibrado para este freezer + produto (ou genérico se productId for null)
  IntColumn get calibratedDurationSeconds => integer()();

  // Quantidade de amostras/ciclos avaliados
  IntColumn get sampleCount => integer().withDefault(const Constant(0))();

  // Último feedback recebido ('on_point', 'soft', 'overchilled', 'auto_ok')
  TextColumn get lastFeedback => text().nullable()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

