import 'package:drift/drift.dart';
import 'package:gm_fabrica_monitoramento/src/domain/models/freezer_event_model.dart';
import 'package:gm_fabrica_monitoramento/src/utils/generator_id.dart';
import 'package:gm_fabrica_monitoramento/src/utils/result.dart';

import '../app_database.dart';
import '../tables/freezer_events_table.dart';
import '../tables/cooling_cycles_table.dart';
import '../tables/freezers_table.dart';
import '../enum/sync_status_enum.dart';

part 'freezer_dao.g.dart';

@DriftAccessor(tables: [FreezerEventsTable, CoolingCyclesTable, FreezersTable])
final class FreezerDao extends DatabaseAccessor<AppDatabase>
    with _$FreezerDaoMixin {
  FreezerDao(super.db);

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
  // CICLOS DE RESFRIAMENTO (Gargalo de Produtividade)
  // ==========================================

  Future<Result<String>> startCoolingCycle(
    String batchId,
    String freezerId,
    int expectedSeconds,
  ) => Result.catchInAsync(
    fn: () async {
      final cycleId = GeneratorId.getid();

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
