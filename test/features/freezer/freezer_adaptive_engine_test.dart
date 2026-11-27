import 'package:flutter_test/flutter_test.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/engine/freezer_adaptive_engine.dart';
import 'package:gm_fabrica_monitoramento/src/features/freezer/domain/models/freezer_feedback_enum.dart';

void main() {
  const engine = FreezerAdaptiveEngine();

  group('FreezerAdaptiveEngine - predictCycleDuration', () {
    test('na faixa nominal (-1.0 °C) sem aumento de temperatura mantém tempo base calibrado', () {
      final duration = engine.predictCycleDuration(
        baseCalibratedSeconds: 1200,
        baselineTemp: -1.0,
        peakTemp: -1.0,
      );
      expect(duration, equals(1200));
    });

    test('adiciona compensação térmica proporcional à câmara quente (+4.0 °C) e ao pico pós-carga (+8.0 °C)', () {
      // Câmara a +4.0°C (5°C acima do nominal -1.0°C) -> 5.0 * 16 = +80s
      // Salto de +4.0°C para +8.0°C (deltaT = 4.0°C) -> 4.0 * 18 = +72s
      // Total = 1200 + 80 + 72 = 1352s
      final duration = engine.predictCycleDuration(
        baseCalibratedSeconds: 1200,
        baselineTemp: 4.0,
        peakTemp: 8.0,
      );
      expect(duration, equals(1352));
    });

    test('aplica bônus de câmara super fria (ex: -8.0 °C no 1º lote da manhã)', () {
      // -8.0°C está 4.0°C abaixo de -4.0°C -> -4 * 12 = -48s -> 1200 - 48 = 1152s
      final duration = engine.predictCycleDuration(
        baseCalibratedSeconds: 1200,
        baselineTemp: -8.0,
        peakTemp: -8.0,
      );
      expect(duration, equals(1152));
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

    test('feedback "autoOk" e "onPoint" após alarme mantêm a calibração base intacta (sem inflação); "onPoint" adiantado reduz', () {
      // autoOk (timeout 30s) -> nunca aumenta o tempo
      final afterAutoOk = engine.adaptCalibration(
        currentCalibratedSeconds: 1200,
        executedEffectiveSeconds: 1300,
        feedback: FreezerFeedbackEnum.autoOk,
      );
      expect(afterAutoOk, equals(1200));

      // onPoint normal após o ciclo dar pronto -> mantém 1200
      final afterNormalOnPoint = engine.adaptCalibration(
        currentCalibratedSeconds: 1200,
        executedEffectiveSeconds: 1250,
        feedback: FreezerFeedbackEnum.onPoint,
        isEarlyManualReady: false,
      );
      expect(afterNormalOnPoint, equals(1200));

      // onPoint acionado manualmente antes do fim (ex: aos 900s de 1200s) -> reduz suavemente
      final afterEarlyReady = engine.adaptCalibration(
        currentCalibratedSeconds: 1200,
        executedEffectiveSeconds: 900,
        feedback: FreezerFeedbackEnum.onPoint,
        isEarlyManualReady: true,
        learningRate: 0.2,
      );
      expect(afterEarlyReady, equals(1140));
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

  group('FreezerAdaptiveEngine - Degelo (Frost Free Desligado)', () {
    test('detectDefrostStart ignora subida térmica durante inércia pós-fechamento da porta (90s)', () {
      final now = DateTime(2026, 11, 24, 15, 0, 0);
      final closedAt = now.subtract(const Duration(seconds: 60)); // fechou há 60s (< 90s)
      final history = [
        (timestamp: now.subtract(const Duration(seconds: 50)), temperature: 0.0),
        (timestamp: now.subtract(const Duration(seconds: 25)), temperature: 1.5),
        (timestamp: now, temperature: 3.0),
      ];

      expect(
        engine.detectDefrostStart(
          currentTemp: 3.0,
          isDoorOpen: false,
          now: now,
          lastDoorCloseAt: closedAt,
          history: history,
        ),
        isFalse,
      );
    });

    test('detectDefrostStart detecta subida contínua >= 2.0 °C com porta fechada após inércia', () {
      final now = DateTime(2026, 11, 24, 15, 0, 0);
      final closedAt = now.subtract(const Duration(minutes: 10));
      final history = [
        (timestamp: now.subtract(const Duration(seconds: 150)), temperature: -2.0),
        (timestamp: now.subtract(const Duration(seconds: 90)), temperature: -1.1),
        (timestamp: now.subtract(const Duration(seconds: 30)), temperature: -0.3),
        (timestamp: now, temperature: 0.2), // subiu 2.2 °C com porta fechada
      ];

      expect(
        engine.detectDefrostStart(
          currentTemp: 0.2,
          isDoorOpen: false,
          now: now,
          lastDoorCloseAt: closedAt,
          history: history,
        ),
        isTrue,
      );
    });

    test('detectDefrostEnd exige queda >= 1.0 °C do pico em ciclo ativo e <= 2.5 °C quando ocioso', () {
      // Com ciclo ativo: pico foi 8.0 °C, caiu para 6.8 °C (queda de 1.2 °C) -> destrava ciclo
      expect(
        engine.detectDefrostEnd(
          currentTemp: 6.8,
          defrostPeakTemp: 8.0,
          hasActiveCycle: true,
        ),
        isTrue,
      );

      // Ocioso (idle): pico foi 8.0 °C, caiu para 5.0 °C (queda de 3.0 °C, mas ainda > 2.5 °C) -> mantém bloqueado para novas formas
      expect(
        engine.detectDefrostEnd(
          currentTemp: 5.0,
          defrostPeakTemp: 8.0,
          hasActiveCycle: false,
        ),
        isFalse,
      );

      // Ocioso (idle): caiu para 2.2 °C (<= 2.5 °C) -> libera "Aguardando Forminhas"
      expect(
        engine.detectDefrostEnd(
          currentTemp: 2.2,
          defrostPeakTemp: 8.0,
          hasActiveCycle: false,
        ),
        isTrue,
      );
    });
  });
}

