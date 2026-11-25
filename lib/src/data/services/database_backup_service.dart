import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:gm_fabrica_monitoramento/src/core/supabase/supabase_bootstrap.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/app_database.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado da geração e envio do backup compactado (.zip) do banco de dados.
final class DatabaseBackupResult {
  final String fileName;
  final String localZipPath;
  final int sizeBytes;
  final DateTime createdAt;
  final bool uploadedToSupabase;
  final String? supabaseStoragePath;
  final String? uploadWarning;
  final Map<String, int> tableRowCounts;

  const DatabaseBackupResult({
    required this.fileName,
    required this.localZipPath,
    required this.sizeBytes,
    required this.createdAt,
    required this.uploadedToSupabase,
    required this.tableRowCounts,
    this.supabaseStoragePath,
    this.uploadWarning,
  });

  int get totalRecords =>
      tableRowCounts.values.fold<int>(0, (sum, count) => sum + count);
}

/// Serviço responsável por gerar o backup completo do banco SQLite local (Drift),
/// empacotar o snapshot `.sqlite` (via `VACUUM INTO`) junto com exportações
/// analíticas em `.json` e `.csv` de todas as tabelas em um arquivo `.zip`,
/// e fazer o upload para o Supabase Storage.
class DatabaseBackupService {
  static const String defaultBucketName = 'database-backups';

  final AppDatabase database;
  final SupabaseClient? _injectedSupabaseClient;
  final Future<Directory> Function()? directoryProvider;
  final String bucketName;

  DatabaseBackupService({
    required this.database,
    SupabaseClient? supabaseClient,
    this.directoryProvider,
    this.bucketName = defaultBucketName,
  }) : _injectedSupabaseClient = supabaseClient;

  SupabaseClient? get _supabase => _injectedSupabaseClient ?? supabaseOrNull;

  /// Executa a rotina completa de backup:
  /// 1. Extrai snapshot íntegro do SQLite via `VACUUM INTO`
  /// 2. Exporta todas as tabelas para JSON e CSV para análise rápida
  /// 3. Compacta tudo em um arquivo `.zip`
  /// 4. Envia o `.zip` para o bucket do Supabase Storage (se autenticado/configurado)
  Future<DatabaseBackupResult> createAndUploadBackup({DateTime? now}) async {
    final timestamp = (now ?? DateTime.now()).toLocal();
    final formattedDate = DateFormat('yyyyMMdd_HHmmss').format(timestamp);
    final zipFileName = 'gm_fabrica_backup_$formattedDate.zip';

    final baseDir = await (directoryProvider != null
        ? directoryProvider!()
        : getApplicationDocumentsDirectory());
    final backupsDir = Directory(p.join(baseDir.path, 'backups'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }

    final snapshotSqliteFile = File(
      p.join(backupsDir.path, 'temp_snapshot_$formattedDate.sqlite'),
    );
    if (await snapshotSqliteFile.exists()) {
      await snapshotSqliteFile.delete();
    }

    final archive = Archive();

    try {
      // 1. Cria snapshot consistente do SQLite via VACUUM INTO
      final escapedSnapshotPath = snapshotSqliteFile.path.replaceAll(
        "'",
        "''",
      );
      await database.customStatement("VACUUM INTO '$escapedSnapshotPath'");

      if (await snapshotSqliteFile.exists()) {
        final sqliteBytes = await snapshotSqliteFile.readAsBytes();
        archive.addFile(
          ArchiveFile(
            'gm_fabrica_edge.sqlite',
            sqliteBytes.length,
            sqliteBytes,
          ),
        );
      }
    } catch (e) {
      debugPrint('Aviso ao executar VACUUM INTO para snapshot SQLite: $e');
      // Fallback caso o banco esteja em memória ou VACUUM INTO falhe:
      final rawDbFile = File(p.join(baseDir.path, 'gm_fabrica_edge.sqlite'));
      if (await rawDbFile.exists()) {
        final sqliteBytes = await rawDbFile.readAsBytes();
        archive.addFile(
          ArchiveFile(
            'gm_fabrica_edge.sqlite',
            sqliteBytes.length,
            sqliteBytes,
          ),
        );
      }
    } finally {
      if (await snapshotSqliteFile.exists()) {
        try {
          await snapshotSqliteFile.delete();
        } catch (_) {}
      }
    }

    // 2. Exporta os dados de todas as tabelas para JSON e CSV
    final tablesData = await _exportAllTables();
    final tableRowCounts = <String, int>{};

    for (final entry in tablesData.entries) {
      final tableName = entry.key;
      final rows = entry.value;
      tableRowCounts[tableName] = rows.length;

      // Arquivo JSON individual da tabela
      final jsonString = const JsonEncoder.withIndent('  ').convert(rows);
      final jsonBytes = utf8.encode(jsonString);
      archive.addFile(
        ArchiveFile('json/$tableName.json', jsonBytes.length, jsonBytes),
      );

      // Arquivo CSV individual da tabela
      final csvString = _convertToCsv(rows);
      final csvBytes = utf8.encode(csvString);
      archive.addFile(
        ArchiveFile('csv/$tableName.csv', csvBytes.length, csvBytes),
      );
    }

    // 3. Adiciona manifesto / metadados do backup e dump consolidado JSON
    final metadata = <String, dynamic>{
      'backup_file': zipFileName,
      'created_at': timestamp.toIso8601String(),
      'schema_version': database.schemaVersion,
      'kiosk_user_email': _supabase?.auth.currentUser?.email,
      'table_row_counts': tableRowCounts,
      'total_records': tableRowCounts.values.fold<int>(0, (a, b) => a + b),
    };

    final metadataBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(metadata),
    );
    archive.addFile(
      ArchiveFile('metadata.json', metadataBytes.length, metadataBytes),
    );

    final fullDumpBytes = utf8.encode(
      const JsonEncoder.withIndent('  ').convert({
        'metadata': metadata,
        'tables': tablesData,
      }),
    );
    archive.addFile(
      ArchiveFile(
        'full_analysis_dump.json',
        fullDumpBytes.length,
        fullDumpBytes,
      ),
    );

    // 4. Codifica o arquivo .zip e grava no diretório local de backups
    final zipBytes = ZipEncoder().encode(archive);
    final zipFile = File(p.join(backupsDir.path, zipFileName));
    await zipFile.writeAsBytes(zipBytes, flush: true);

    // 5. Envia para o Supabase Storage (se o cliente Supabase estiver disponível)
    bool uploaded = false;
    String? storagePath;
    String? uploadWarning;

    final client = _supabase;
    if (client != null) {
      final dateFolder = DateFormat('yyyy-MM-dd').format(timestamp);
      final remotePath = '$dateFolder/$zipFileName';
      try {
        await client.storage.from(bucketName).uploadBinary(
          remotePath,
          Uint8List.fromList(zipBytes),
          fileOptions: const FileOptions(
            contentType: 'application/zip',
            upsert: true,
          ),
        );
        uploaded = true;
        storagePath = '$bucketName/$remotePath';
      } catch (e) {
        uploadWarning =
            'Backup salvo localmente, mas falhou ao enviar ao Supabase Storage ($bucketName): $e';
        debugPrint(uploadWarning);
      }
    } else {
      uploadWarning =
          'Supabase não conectado. Backup salvo localmente no dispositivo.';
    }

    return DatabaseBackupResult(
      fileName: zipFileName,
      localZipPath: zipFile.path,
      sizeBytes: zipBytes.length,
      createdAt: timestamp,
      uploadedToSupabase: uploaded,
      supabaseStoragePath: storagePath,
      uploadWarning: uploadWarning,
      tableRowCounts: tableRowCounts,
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _exportAllTables() async {
    final products = await database.select(database.productsTable).get();
    final freezers = await database.select(database.freezersTable).get();
    final batches = await database
        .select(database.productionBatchesTable)
        .get();
    final adjustments = await database
        .select(database.batchAdjustmentsTable)
        .get();
    final timelines = await database
        .select(database.productionTimeLinesTable)
        .get();
    final coolingCycles = await database
        .select(database.coolingCyclesTable)
        .get();
    final calibrations = await database
        .select(database.freezerCalibrationsTable)
        .get();
    final freezerEvents = await database
        .select(database.freezerEventsTable)
        .get();
    final roomEvents = await database.select(database.roomEventsTable).get();

    return {
      'products': [
        for (final r in products)
          {
            'id': r.id,
            'name': r.name,
            'unit_weight_grams': r.unitWeightGrams,
            'category': r.category,
            'ean_code': r.eanCode,
            'default_box_capacity': r.defaultBoxCapacity,
            'default_cooling_seconds': r.defaultCoolingSeconds,
            'is_active': r.isActive,
            'sync_status': r.syncStatus.name,
          },
      ],
      'freezers': [
        for (final r in freezers)
          {
            'id': r.id,
            'id_sensor': r.idSensor,
            'name': r.name,
            'description': r.description,
            'equipment_id': r.equipmentId,
            'equipment_name': r.equipmentName,
            'target_temperature': r.targetTemperature,
            'default_cooling_seconds': r.defaultCoolingSeconds,
            'unload_min_seconds': r.unloadMinSeconds,
            'reload_min_seconds': r.reloadMinSeconds,
            'sync_status': r.syncStatus.name,
          },
      ],
      'production_batches': [
        for (final r in batches)
          {
            'id': r.id,
            'product_id': r.productId,
            'initial_hardware_count': r.initialHardwareCount,
            'final_hardware_count': r.finalHardwareCount,
            'gross_count': r.finalHardwareCount != null
                ? (r.finalHardwareCount! - r.initialHardwareCount)
                : null,
            'started_at': r.startedAt.toIso8601String(),
            'finished_at': r.finishedAt?.toIso8601String(),
            'sync_status': r.syncStatus.name,
          },
      ],
      'batch_adjustments': [
        for (final r in adjustments)
          {
            'id': r.id,
            'batch_id': r.batchId,
            'delta_qty': r.deltaQty,
            'reason': r.reason.name,
            'reason_label': r.reason.label,
            'observation': r.observation,
            'created_at': r.createdAt.toIso8601String(),
            'sync_status': r.syncStatus.name,
          },
      ],
      'production_timelines': [
        for (final r in timelines)
          {
            'id': r.id,
            'batch_id': r.batchId,
            'current_hardware_count': r.currentHardwareCount,
            'recorded_at': r.recordedAt.toIso8601String(),
            'sync_status': r.syncStatus.name,
          },
      ],
      'cooling_cycles': [
        for (final r in coolingCycles)
          {
            'id': r.id,
            'batch_id': r.batchId,
            'freezer_id': r.freezerId,
            'started_at': r.startedAt.toIso8601String(),
            'finished_at': r.finishedAt?.toIso8601String(),
            'baseline_temp': r.baselineTemp,
            'initial_peak_temp': r.initialPeakTemp,
            'expected_duration_seconds': r.expectedDurationSeconds,
            'actual_duration_seconds': r.actualDurationSeconds,
            'accumulated_door_open_seconds': r.accumulatedDoorOpenSeconds,
            'accumulated_penalty_seconds': r.accumulatedPenaltySeconds,
            'door_open_count': r.doorOpenCount,
            'accumulated_defrost_seconds': r.accumulatedDefrostSeconds,
            'feedback': r.feedback,
            'sync_status': r.syncStatus.name,
          },
      ],
      'freezer_calibrations': [
        for (final r in calibrations)
          {
            'id': r.id,
            'freezer_id': r.freezerId,
            'product_id': r.productId,
            'calibrated_duration_seconds': r.calibratedDurationSeconds,
            'sample_count': r.sampleCount,
            'last_feedback': r.lastFeedback,
            'updated_at': r.updatedAt.toIso8601String(),
            'sync_status': r.syncStatus.name,
          },
      ],
      'freezer_events': [
        for (final r in freezerEvents)
          {
            'id': r.id,
            'freezer_id': r.freezerId,
            'batch_id': r.batchId,
            'recorded_at': r.recordedAt.toIso8601String(),
            'temperature': r.temperature,
            'is_door_open': r.isDoorOpen,
            'trigger_reason': r.triggerReason.name,
            'sync_status': r.syncStatus.name,
          },
      ],
      'room_events': [
        for (final r in roomEvents)
          {
            'id': r.id,
            'batch_id': r.batchId,
            'recorded_at': r.recordedAt.toIso8601String(),
            'temperature': r.temperature,
            'humidity': r.humidity,
            'sync_status': r.syncStatus.name,
          },
      ],
    };
  }

  String _convertToCsv(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return '';
    final headers = rows.first.keys.toList();
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_escapeCsvField).join(','));

    for (final row in rows) {
      final values = headers.map((h) => _escapeCsvField(row[h])).join(',');
      buffer.writeln(values);
    }
    return buffer.toString();
  }

  String _escapeCsvField(Object? value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains(',') ||
        str.contains('"') ||
        str.contains('\n') ||
        str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }
}
