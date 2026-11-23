import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_event_model.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_model.dart';
import 'package:gm_fabrica_monitoramento/src/utils/generator_id.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';

import '../app_database.dart';
import '../tables/freezer_events_table.dart';
import '../tables/cooling_cycles_table.dart';
import '../tables/freezers_table.dart';
import '../tables/freezer_calibrations_table.dart';
import '../enum/sync_status_enum.dart';

part 'freezer_dao.g.dart';

@DriftAccessor(
  tables: [
    FreezerEventsTable,
    CoolingCyclesTable,
    FreezersTable,
    FreezerCalibrationsTable,
  ],
)
final class FreezerDao extends DatabaseAccessor<AppDatabase>
    with _$FreezerDaoMixin {
  FreezerDao(super.db);

  // ==========================================
  // CADASTRO E VÍNCULO DOS FREEZERS <-> SENSORES
  // ==========================================

  /// Garante que as linhas base dos sensores `f1` e `f2` existam no SQLite
  /// para satisfazer as Foreign Keys de ciclos, calibrações e eventos.
  Future<Result<List<Freezer>>> ensureSensorFreezersExist() =>
      Result.catchInAsync(
        fn: () async {
          final existing = await select(freezersTable).get();
          final existingIds = {for (final f in existing) f.id};

          if (!existingIds.contains('f1')) {
            await into(freezersTable).insert(
              FreezersTableCompanion.insert(
                id: 'f1',
                idSensor: 1,
                name: 'Sensor 1 (F1)',
                defaultCoolingSeconds: const Value(480),
                targetTemperature: const Value(4.0),
              ),
            );
          }

          if (!existingIds.contains('f2')) {
            await into(freezersTable).insert(
              FreezersTableCompanion.insert(
                id: 'f2',
                idSensor: 2,
                name: 'Sensor 2 (F2)',
                defaultCoolingSeconds: const Value(480),
                targetTemperature: const Value(-18.0),
              ),
            );
          }

          // Atualiza registros legados (1200s / 900s) para o novo padrão inicial de 8 minutos (480s)
          await (update(freezersTable)
                ..where(
                  (f) => f.defaultCoolingSeconds.isIn(const [900, 1200]),
                ))
              .write(
                const FreezersTableCompanion(
                  defaultCoolingSeconds: Value(480),
                ),
              );

          return (select(
            freezersTable,
          )..orderBy([(t) => OrderingTerm.asc(t.idSensor)])).get();
        },
        tag: 'FreezerDao.ensureSensorFreezersExist',
      );

  /// Salva no SQLite local o vínculo entre um sensor (`f1`, `f2`) e o equipamento do Supabase (`cost_centers`).
  Future<Result<Freezer>> upsertFreezerBinding(
    FreezerSensorBindingModel binding,
  ) => Result.catchInAsync(
    fn: () async {
      await into(freezersTable).insertOnConflictUpdate(
        FreezersTableCompanion.insert(
          id: binding.sensorKey,
          idSensor: binding.sensorIndex,
          name: binding.resolvedDisplayName,
          description: Value(binding.customLabel),
          equipmentId: Value(binding.costCenterId),
          equipmentName: Value(binding.costCenterName),
          targetTemperature: Value(binding.targetTemperature),
          defaultCoolingSeconds: Value(binding.defaultCoolingSeconds),
          unloadMinSeconds: Value(binding.unloadMinSeconds),
          reloadMinSeconds: Value(binding.reloadMinSeconds),
          syncStatus: const Value(SyncStatusEnum.synced),
        ),
      );

      return (select(
        freezersTable,
      )..where((f) => f.id.equals(binding.sensorKey))).getSingle();
    },
    tag: 'FreezerDao.upsertFreezerBinding',
  );

  /// Busca todas as configurações locais de sensores/freezers
  Future<Result<List<Freezer>>> getFreezers() => Result.catchInAsync(
    fn: () async {
      return (select(
        freezersTable,
      )..orderBy([(t) => OrderingTerm.asc(t.idSensor)])).get();
    },
    tag: 'FreezerDao.getFreezers',
  );

  // ==========================================
  // TELEMETRIA E EVENTOS
  // ==========================================

  Future<Result<Unit>> logFreezerEvent({required FreezerEventModel event}) =>
      Result.catchInAsync(
        fn: () async {
          await into(freezerEventsTable).insert(
            FreezerEventsTableCompanion.insert(
              id: event.id,
              batchId: event.batch.id,
              freezerId: event.freezer.id,
              temperature: event.temperature,
              isDoorOpen: event.isDoorOpen,
              triggerReason: event.triggerReason,
            ),
          );

          return unit;
        },
        tag: 'FreezerDao.logFreezerEvent',
      );

  // ==========================================
  // CALIBRAÇÃO ADAPTATIVA
  // ==========================================

  /// Busca calibração específica para [freezerId] e [productId].
  /// Se não encontrar para o produto, busca o padrão genérico (productId == null).
  Future<Result<FreezerCalibration?>> getCalibration(
    String freezerId, {
    String? productId,
  }) => Result.catchInAsync(
    fn: () async {
      if (productId != null) {
        final specific = await (select(freezerCalibrationsTable)
              ..where(
                (tbl) =>
                    tbl.freezerId.equals(freezerId) &
                    tbl.productId.equals(productId),
              ))
            .getSingleOrNull();

        if (specific != null) return specific;
      }

      // Fallback para calibração genérica (sem produto específico)
      final generic = await (select(freezerCalibrationsTable)
            ..where(
              (tbl) =>
                  tbl.freezerId.equals(freezerId) & tbl.productId.isNull(),
            ))
          .getSingleOrNull();

      return generic;
    },
    tag: 'FreezerDao.getCalibration',
  );

  /// Retorna todas as calibrações de um freezer (para tela de configurações)
  Future<Result<List<FreezerCalibration>>> getAllCalibrationsForFreezer(
    String freezerId,
  ) => Result.catchInAsync(
    fn: () async {
      return (select(freezerCalibrationsTable)
            ..where((tbl) => tbl.freezerId.equals(freezerId))
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
          .get();
    },
    tag: 'FreezerDao.getAllCalibrationsForFreezer',
  );

  /// Insere ou atualiza a calibração com novo tempo aprendido e feedback
  Future<Result<FreezerCalibration>> upsertCalibration({
    required String freezerId,
    String? productId,
    required int calibratedDurationSeconds,
    required String lastFeedback,
  }) => Result.catchInAsync(
    fn: () async {
      final existing = await (select(freezerCalibrationsTable)
            ..where(
              (tbl) =>
                  tbl.freezerId.equals(freezerId) &
                  (productId != null
                      ? tbl.productId.equals(productId)
                      : tbl.productId.isNull()),
            ))
          .getSingleOrNull();

      final now = DateTime.now();

      if (existing != null) {
        await (update(freezerCalibrationsTable)
              ..where((tbl) => tbl.id.equals(existing.id)))
            .write(
              FreezerCalibrationsTableCompanion(
                calibratedDurationSeconds: Value(calibratedDurationSeconds),
                sampleCount: Value(existing.sampleCount + 1),
                lastFeedback: Value(lastFeedback),
                updatedAt: Value(now),
                syncStatus: const Value(SyncStatusEnum.updating),
              ),
            );

        return (select(freezerCalibrationsTable)
              ..where((tbl) => tbl.id.equals(existing.id)))
            .getSingle();
      } else {
        final newId = GeneratorId.getid();
        final companion = FreezerCalibrationsTableCompanion.insert(
          id: newId,
          freezerId: freezerId,
          productId: Value(productId),
          calibratedDurationSeconds: calibratedDurationSeconds,
          sampleCount: const Value(1),
          lastFeedback: Value(lastFeedback),
          updatedAt: Value(now),
        );

        await into(freezerCalibrationsTable).insert(companion);

        return (select(freezerCalibrationsTable)
              ..where((tbl) => tbl.id.equals(newId)))
            .getSingle();
      }
    },
    tag: 'FreezerDao.upsertCalibration',
  );

  /// Reseta a calibração de um freezer/produto para o valor padrão de fábrica
  Future<Result<Unit>> resetCalibration({
    required String freezerId,
    String? productId,
    required int defaultSeconds,
  }) => Result.catchInAsync(
    fn: () async {
      final existing = await (select(freezerCalibrationsTable)
            ..where(
              (tbl) =>
                  tbl.freezerId.equals(freezerId) &
                  (productId != null
                      ? tbl.productId.equals(productId)
                      : tbl.productId.isNull()),
            ))
          .getSingleOrNull();

      final now = DateTime.now();

      if (existing != null) {
        await (update(freezerCalibrationsTable)
              ..where((tbl) => tbl.id.equals(existing.id)))
            .write(
              FreezerCalibrationsTableCompanion(
                calibratedDurationSeconds: Value(defaultSeconds),
                sampleCount: const Value(0),
                lastFeedback: const Value(null),
                updatedAt: Value(now),
                syncStatus: const Value(SyncStatusEnum.updating),
              ),
            );
      } else {
        await into(freezerCalibrationsTable).insert(
          FreezerCalibrationsTableCompanion.insert(
            id: GeneratorId.getid(),
            freezerId: freezerId,
            productId: Value(productId),
            calibratedDurationSeconds: defaultSeconds,
            sampleCount: const Value(0),
            updatedAt: Value(now),
          ),
        );
      }

      await (update(freezersTable)..where((f) => f.id.equals(freezerId))).write(
        FreezersTableCompanion(defaultCoolingSeconds: Value(defaultSeconds)),
      );
      return unit;
    },
    tag: 'FreezerDao.resetCalibration',
  );

  // ==========================================
  // CICLOS DE RESFRIAMENTO
  // ==========================================

  Future<Result<String>> startCoolingCycle({
    String? batchId,
    required String freezerId,
    required int expectedSeconds,
    double? baselineTemp,
    double? initialPeakTemp,
  }) => Result.catchInAsync(
    fn: () async {
      final cycleId = GeneratorId.getid();

      await into(coolingCyclesTable).insert(
        CoolingCyclesTableCompanion.insert(
          id: cycleId,
          batchId: Value(batchId),
          freezerId: freezerId,
          expectedDurationSeconds: expectedSeconds,
          baselineTemp: Value(baselineTemp),
          initialPeakTemp: Value(initialPeakTemp),
        ),
      );
      return cycleId;
    },
    tag: 'FreezerDao.startCoolingCycle',
  );

  Future<Result<Unit>> updateCoolingCycleMetrics({
    required String cycleId,
    required int accumulatedDoorOpenSeconds,
    required int accumulatedPenaltySeconds,
    required int doorOpenCount,
  }) => Result.catchInAsync(
    fn: () async {
      await (update(
        coolingCyclesTable,
      )..where((c) => c.id.equals(cycleId))).write(
        CoolingCyclesTableCompanion(
          accumulatedDoorOpenSeconds: Value(accumulatedDoorOpenSeconds),
          accumulatedPenaltySeconds: Value(accumulatedPenaltySeconds),
          doorOpenCount: Value(doorOpenCount),
          syncStatus: const Value(SyncStatusEnum.updating),
        ),
      );

      return unit;
    },
    tag: 'FreezerDao.updateCoolingCycleMetrics',
  );

  Future<Result<Unit>> finishCoolingCycle({
    required String cycleId,
    required int actualSeconds,
    required int accumulatedDoorOpenSeconds,
    required int accumulatedPenaltySeconds,
    required int doorOpenCount,
    String? feedback,
  }) => Result.catchInAsync(
    fn: () async {
      await (update(
        coolingCyclesTable,
      )..where((c) => c.id.equals(cycleId))).write(
        CoolingCyclesTableCompanion(
          actualDurationSeconds: Value(actualSeconds),
          accumulatedDoorOpenSeconds: Value(accumulatedDoorOpenSeconds),
          accumulatedPenaltySeconds: Value(accumulatedPenaltySeconds),
          doorOpenCount: Value(doorOpenCount),
          feedback: Value(feedback),
          finishedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatusEnum.updating),
        ),
      );

      return unit;
    },
    tag: 'FreezerDao.finishCoolingCycle',
  );

  Future<Result<CoolingCycle?>> getActiveCoolingCycle(String freezerId) =>
      Result.catchInAsync(
        fn: () async {
          return (select(coolingCyclesTable)
                ..where(
                  (c) => c.freezerId.equals(freezerId) & c.finishedAt.isNull(),
                )
                ..orderBy([(c) => OrderingTerm.desc(c.startedAt)])
                ..limit(1))
              .getSingleOrNull();
        },
        tag: 'FreezerDao.getActiveCoolingCycle',
      );

  Future<Result<List<CoolingCycle>>> getRecentCycles(
    String freezerId, {
    int limit = 10,
  }) => Result.catchInAsync(
    fn: () async {
      return (select(coolingCyclesTable)
            ..where((c) => c.freezerId.equals(freezerId))
            ..orderBy([(c) => OrderingTerm.desc(c.startedAt)])
            ..limit(limit))
          .get();
    },
    tag: 'FreezerDao.getRecentCycles',
  );
}
