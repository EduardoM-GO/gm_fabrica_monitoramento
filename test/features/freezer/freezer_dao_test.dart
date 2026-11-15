import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/app_database.dart';
import 'package:gm_fabrica_monitoramento/src/data/local/daos/freezer_dao.dart';

void main() {
  late AppDatabase db;
  late FreezerDao freezerDao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    freezerDao = db.freezerDao;

    // Inserir freezers para satisfazer Foreign Keys
    await db.into(db.freezersTable).insert(
      FreezersTableCompanion.insert(
        id: 'f1',
        name: 'Freezer 1 (Câmara)',
        description: const Value('Câmara fria para cristalização'),
        idSensor: 1,
      ),
    );
    await db.into(db.freezersTable).insert(
      FreezersTableCompanion.insert(
        id: 'f2',
        name: 'Freezer 2 (Congelador)',
        description: const Value('Congelamento rápido'),
        idSensor: 2,
      ),
    );

    // Inserir produto de teste
    await db.into(db.productsTable).insert(
      ProductsTableCompanion.insert(
        id: 'prod_250g',
        name: 'Ovo de Páscoa 250g',
        unitWeightGrams: 250.0,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('FreezerDao - Calibração Adaptativa', () {
    test('upsertCalibration cria calibração genérica quando productId é null', () async {
      final result = await freezerDao.upsertCalibration(
        freezerId: 'f1',
        calibratedDurationSeconds: 1200,
        lastFeedback: 'on_point',
      );

      expect(result.isOk, isTrue);
      final cal = result.valueOrThrow;
      expect(cal.freezerId, equals('f1'));
      expect(cal.productId, isNull);
      expect(cal.calibratedDurationSeconds, equals(1200));
      expect(cal.sampleCount, equals(1));
      expect(cal.lastFeedback, equals('on_point'));
    });

    test('getCalibration retorna específico se existir, ou fallback para genérico', () async {
      // 1. Cria genérico (1200s)
      await freezerDao.upsertCalibration(
        freezerId: 'f1',
        calibratedDurationSeconds: 1200,
        lastFeedback: 'auto_ok',
      );

      // Busca para prod_250g antes de ter específico -> deve vir o genérico
      final fallbackRes = await freezerDao.getCalibration('f1', productId: 'prod_250g');
      expect(fallbackRes.isOk, isTrue);
      expect(fallbackRes.valueOrThrow?.calibratedDurationSeconds, equals(1200));

      // 2. Cria específico para prod_250g (1350s)
      await freezerDao.upsertCalibration(
        freezerId: 'f1',
        productId: 'prod_250g',
        calibratedDurationSeconds: 1350,
        lastFeedback: 'soft',
      );

      final specificRes = await freezerDao.getCalibration('f1', productId: 'prod_250g');
      expect(specificRes.isOk, isTrue);
      expect(specificRes.valueOrThrow?.calibratedDurationSeconds, equals(1350));
      expect(specificRes.valueOrThrow?.productId, equals('prod_250g'));
    });

    test('resetCalibration redefine tempo para default e zera contagem de amostras', () async {
      await freezerDao.upsertCalibration(
        freezerId: 'f1',
        calibratedDurationSeconds: 1450,
        lastFeedback: 'soft',
      );

      final resetRes = await freezerDao.resetCalibration(
        freezerId: 'f1',
        defaultSeconds: 1200,
      );
      expect(resetRes.isOk, isTrue);

      final check = await freezerDao.getCalibration('f1');
      expect(check.valueOrThrow?.calibratedDurationSeconds, equals(1200));
      expect(check.valueOrThrow?.sampleCount, equals(0));
      expect(check.valueOrThrow?.lastFeedback, isNull);
    });
  });

  group('FreezerDao - Ciclos de Resfriamento', () {
    test('fluxo completo de ciclo: start -> updateMetrics -> finish com feedback', () async {
      final startRes = await freezerDao.startCoolingCycle(
        freezerId: 'f1',
        expectedSeconds: 1200,
        baselineTemp: 4.5,
        initialPeakTemp: 8.2,
      );
      expect(startRes.isOk, isTrue);
      final cycleId = startRes.valueOrThrow;

      final active = await freezerDao.getActiveCoolingCycle('f1');
      expect(active.isOk, isTrue);
      expect(active.valueOrThrow?.id, equals(cycleId));
      expect(active.valueOrThrow?.initialPeakTemp, equals(8.2));

      // Atualiza métricas durante o ciclo (abertura de porta indevida)
      await freezerDao.updateCoolingCycleMetrics(
        cycleId: cycleId,
        accumulatedDoorOpenSeconds: 15,
        accumulatedPenaltySeconds: 45,
        doorOpenCount: 2,
      );

      // Finaliza o ciclo
      final finishRes = await freezerDao.finishCoolingCycle(
        cycleId: cycleId,
        actualSeconds: 1245,
        accumulatedDoorOpenSeconds: 15,
        accumulatedPenaltySeconds: 45,
        doorOpenCount: 2,
        feedback: 'on_point',
      );
      expect(finishRes.isOk, isTrue);

      // Não deve mais ter ciclo ativo
      final afterFinish = await freezerDao.getActiveCoolingCycle('f1');
      expect(afterFinish.valueOrThrow, isNull);

      // Deve constar no histórico
      final history = await freezerDao.getRecentCycles('f1', limit: 5);
      expect(history.valueOrThrow.length, equals(1));
      expect(history.valueOrThrow.first.feedback, equals('on_point'));
      expect(history.valueOrThrow.first.accumulatedPenaltySeconds, equals(45));
    });
  });
}
