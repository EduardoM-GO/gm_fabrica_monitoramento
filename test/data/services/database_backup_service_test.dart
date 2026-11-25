import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/app_database.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/adjustment_reason_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/enum/sync_status_enum.dart';
import 'package:gm_fabrica_monitoramento/src/data/services/database_backup_service.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gm_backup_test_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'DatabaseBackupService generates .zip containing sqlite snapshot, metadata, json and csv files',
    () async {
      // Seed sample data across tables
      await db.into(db.productsTable).insert(
        ProductsTableCompanion.insert(
          id: 'prod_1',
          name: 'Ovo Trufado 400g',
          unitWeightGrams: 400.0,
        ),
      );

      await db.into(db.freezersTable).insert(
        FreezersTableCompanion.insert(
          id: 'f1',
          idSensor: 1,
          name: 'Freezer 01',
        ),
      );

      final startedAt = DateTime(2026, 11, 24, 14, 30);
      await db.into(db.productionBatchesTable).insert(
        ProductionBatchesTableCompanion.insert(
          id: 'batch_1',
          productId: 'prod_1',
          initialHardwareCount: 100,
        ),
      );

      await db.into(db.batchAdjustmentsTable).insert(
        BatchAdjustmentsTableCompanion.insert(
          id: 'adj_1',
          batchId: 'batch_1',
          deltaQty: -2,
          reason: AdjustmentReasonEnum.brokenShell,
        ),
      );

      final service = DatabaseBackupService(
        database: db,
        directoryProvider: () async => tempDir,
      );

      final result = await service.createAndUploadBackup(now: startedAt);

      expect(result.fileName, 'gm_fabrica_backup_20261124_143000.zip');
      expect(result.totalRecords, 4);
      expect(result.tableRowCounts['products'], 1);
      expect(result.tableRowCounts['freezers'], 1);
      expect(result.tableRowCounts['production_batches'], 1);
      expect(result.tableRowCounts['batch_adjustments'], 1);

      final zipFile = File(result.localZipPath);
      expect(await zipFile.exists(), isTrue);

      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final fileNames = archive.files.map((f) => f.name).toSet();

      expect(fileNames, contains('gm_fabrica_edge.sqlite'));
      expect(fileNames, contains('metadata.json'));
      expect(fileNames, contains('full_analysis_dump.json'));
      expect(fileNames, contains('json/products.json'));
      expect(fileNames, contains('csv/products.csv'));
      expect(fileNames, contains('json/production_batches.json'));
      expect(fileNames, contains('csv/batch_adjustments.csv'));

      // Verify JSON content
      final productsJsonFile = archive.findFile('json/products.json')!;
      final productsJson =
          jsonDecode(utf8.decode(productsJsonFile.content as List<int>))
              as List;
      expect(productsJson.single['name'], 'Ovo Trufado 400g');
      expect(productsJson.single['sync_status'], SyncStatusEnum.pending.name);

      // Verify CSV content
      final adjustmentsCsvFile = archive.findFile('csv/batch_adjustments.csv')!;
      final adjustmentsCsv = utf8.decode(
        adjustmentsCsvFile.content as List<int>,
      );
      expect(adjustmentsCsv, contains('id,batch_id,delta_qty,reason'));
      expect(adjustmentsCsv, contains('adj_1,batch_1,-2,brokenShell'));
    },
  );
}
