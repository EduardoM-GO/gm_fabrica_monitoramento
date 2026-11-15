import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/engine/freezer_adaptive_engine.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_feedback_enum.dart';

void main() {
  const engine = FreezerAdaptiveEngine();

  group('FreezerAdaptiveEngine - predictCycleDuration', () {
    test('sem aumento de temperatura mantém tempo base calibrado', () {
      final duration = engine.predictCycleDuration(
        baseCalibratedSeconds: 1200,
        baselineTemp: 4.0,
        peakTemp: 4.0,
      );
      expect(duration, equals(1200));
    });

    test('adiciona compensação térmica proporcional ao pico de calor pós-carga', () {
      // 4.0°C subiu para 8.0°C (deltaT = 4.0°C) -> 4.0 * 18 = 72 segundos extras
      final duration = engine.predictCycleDuration(
        baseCalibratedSeconds: 1200,
        baselineTemp: 4.0,
        peakTemp: 8.0,
      );
      expect(duration, equals(1272));
    });

    test('respeita os limites min e max de segurança', () {
      final clampedMin = engine.predictCycleDuration(
        baseCalibratedSeconds: 100,
        baselineTemp: 4.0,
        peakTemp: 4.0,
        minDurationSeconds: 300,
      );
      expect(clampedMin, equals(300));

      final clampedMax = engine.predictCycleDuration(
        baseCalibratedSeconds: 3500,
        baselineTemp: 4.0,
        peakTemp: 30.0,
        maxDurationSeconds: 3600,
      );
      expect(clampedMax, equals(3600));
    });
  });

  group('FreezerAdaptiveEngine - calculateDoorPenalty', () {
    test('porta não aberta resulta em 0 segundos de penalidade', () {
      final penalty = engine.calculateDoorPenalty(
        doorOpenSeconds: 0,
        tempRise: 0.0,
      );
      expect(penalty, equals(0));
    });

    test('calcula perda convectiva + recuperação térmica do compressor', () {
      // 10s aberta * 1.3 = 13s
      // 2.0°C subida * 30.0 = 60s
      // Total = 73s
      final penalty = engine.calculateDoorPenalty(
        doorOpenSeconds: 10,
        tempRise: 2.0,
      );
      expect(penalty, equals(73));
    });

    test('limita penalidade máxima por segurança (evita loop infinito de tempo)', () {
      final penalty = engine.calculateDoorPenalty(
        doorOpenSeconds: 600,
        tempRise: 20.0,
        maxPenaltySeconds: 360,
      );
      expect(penalty, equals(360));
    });
  });

  group('FreezerAdaptiveEngine - isInspectionOnly', () {
    test('abertura de 8 segundos com limiar de 12s é classificada como inspeção', () {
      expect(engine.isInspectionOnly(doorOpenSeconds: 8, inspectionThresholdSeconds: 12), isTrue);
    });

    test('abertura de 25 segundos é classificada como carregamento/troca', () {
      expect(engine.isInspectionOnly(doorOpenSeconds: 25, inspectionThresholdSeconds: 12), isFalse);
    });
  });

  group('FreezerAdaptiveEngine - adaptCalibration (Closed Loop)', () {
    test('feedback "soft" (Ainda Mole) aumenta tempo base calibrado', () {
      final updated = engine.adaptCalibration(
        currentCalibratedSeconds: 1200,
        executedEffectiveSeconds: 1200,
        feedback: FreezerFeedbackEnum.soft,
      );
      // 1200 + max(90, 1200 * 0.08 = 96) = 1296
      expect(updated, equals(1296));
    });

    test('feedback "overchilled" (Muito Gelado) reduz tempo base calibrado', () {
      final updated = engine.adaptCalibration(
        currentCalibratedSeconds: 1200,
        executedEffectiveSeconds: 1200,
        feedback: FreezerFeedbackEnum.overchilled,
      );
      // 1200 - max(60, 1200 * 0.05 = 60) = 1140
      expect(updated, equals(1140));
    });

    test('feedback "onPoint" / "autoOk" converge suavemente para tempo real executado', () {
      final updated = engine.adaptCalibration(
        currentCalibratedSeconds: 1200,
        executedEffectiveSeconds: 1300,
        feedback: FreezerFeedbackEnum.onPoint,
        learningRate: 0.1,
      );
      // 1200 + (1300 - 1200) * 0.1 = 1210
      expect(updated, equals(1210));
    });
  });

  group('FreezerAdaptiveEngine - immediateExtensionSeconds', () {
    test('retorna 180s (3min) quando feedback for soft', () {
      expect(
        engine.immediateExtensionSeconds(feedback: FreezerFeedbackEnum.soft),
        equals(180),
      );
    });

    test('retorna 0s quando feedback for onPoint', () {
      expect(
        engine.immediateExtensionSeconds(feedback: FreezerFeedbackEnum.onPoint),
        equals(0),
      );
    });
  });
}

