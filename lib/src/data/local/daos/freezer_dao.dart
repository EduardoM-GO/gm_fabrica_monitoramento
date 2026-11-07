import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/utils/generator_id.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';

import '../app_database.dart';
import '../tables/freezer_events_table.dart';
import '../tables/cooling_cycles_table.dart';
import '../tables/freezers_table.dart';
import '../enum/trigger_freezer_enum.dart';
import '../enum/sync_status_enum.dart';

part 'freezer_dao.g.dart';

@DriftAccessor(tables: [FreezerEventsTable, CoolingCyclesTable, FreezersTable])
final class FreezerDao extends DatabaseAccessor<AppDatabase>
    with _$FreezerDaoMixin {
  final GeneratorId _generatorId;
  FreezerDao(super.db) : _generatorId = GeneratorId();

  // ==========================================
  // TELEMETRIA E EVENTOS
  // ==========================================

  Future<Result<Unit>> logFreezerEvent(
    String freezerId,
    double temp,
    bool doorOpen,
    TriggerFreezerEnum trigger,
  ) => Result.catchInAsync(
    fn: () async {
      await into(freezerEventsTable).insert(
        FreezerEventsTableCompanion.insert(
          id: _generatorId.getid(),
          freezerId: freezerId,
          temperature: temp,
          doorOpen: doorOpen,
          triggerReason: trigger,
        ),
      );

      return unit;
    },
    tag: 'FreezerDao.logFreezerEvent',
  );

  // ==========================================
  // CICLOS DE RESFRIAMENTO (Gargalo de Produtividade)
  // ==========================================

  Future<Result<String>> startCoolingCycle(
    String batchId,
    String freezerId,
    int expectedSeconds,
  ) => Result.catchInAsync(
    fn: () async {
      final cycleId = _generatorId.getid();
      await into(coolingCyclesTable).insert(
        CoolingCyclesTableCompanion.insert(
          id: cycleId,
          batchId: batchId,
          freezerId: freezerId,
          expectedDurationSeconds: expectedSeconds,
        ),
      );
      return cycleId;
    },
    tag: 'FreezerDao.startCoolingCycle',
  );

  Future<Result<Unit>> finishCoolingCycle(
    String cycleId,
    int actualSeconds,
    int doorOpenSeconds,
  ) => Result.catchInAsync(
    fn: () async {
      await (update(
        coolingCyclesTable,
      )..where((c) => c.id.equals(cycleId))).write(
        CoolingCyclesTableCompanion(
          actualDurationSeconds: Value(actualSeconds),
          accumulatedDoorOpenSeconds: Value(doorOpenSeconds),
          finishedAt: Value(DateTime.now()),
          syncStatus: const Value(SyncStatusEnum.updating),
        ),
      );

      return unit;
    },
    tag: 'FreezerDao.finishCoolingCycle',
  );
}
