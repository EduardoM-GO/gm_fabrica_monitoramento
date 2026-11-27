import 'dart:math';

import '../models/freezer_feedback_enum.dart';

/// Classificação automática do movimento da porta quando o lote está pronto (`ready`)
/// ou na reta final do resfriamento (`>= 85%`), eliminando parâmetros manuais de tempo.
enum DoorReadyActionEnum {
  /// Abertura rápida (<= 8s e ΔT < 1.2 °C): apenas olhou / verificou os ovos.
  quickInspection,

  /// Abertura moderada (9s a 21s e ΔT < 2.3 °C): apenas retirou as formas prontas e fechou o freezer vazio.
  unloadOnly,

  /// Abertura de troca completa (>= 22s ou salto térmico ΔT >= 2.3 °C): retirou o lote pronto e já reabasteceu com formas novas.
  unloadAndReload,
}

/// Motor matemático e termodinâmico para estimativa, compensação dinâmica de temperatura,
/// antecipação do tempo de reação da porta e aprendizado em malha fechada.
final class FreezerAdaptiveEngine {
  const FreezerAdaptiveEngine();

  /// 1. Estima a duração total do ciclo baseada no tempo calibrado do produto,
  /// na temperatura real da câmara no início do ciclo ([baselineTemp]) e no pico pós-porta ([peakTemp]).
  ///
  /// Física real extraída dos dados da fábrica (`F1` e `F2`):
  /// - Referência nominal da câmara: `-2.0 °C`.
  /// - Se o freezer iniciar quente (`baselineTemp > -1.0 °C`, ex: `+4 °C` ou `+6 °C` após várias trocas seguidas),
  ///   soma `+16s` por grau acima de `-1.0 °C` + `+18s` por grau de salto térmico (`peakTemp - baselineTemp`),
  ///   evitando ciclos curtos demais quando a câmara está em `+5 °C`.
  /// - Se o freezer iniciar super gelado (`baselineTemp < -4.0 °C`, ex: `-9 °C` na 1ª fornada da manhã),
  ///   concede bônus de câmara fria (`-12s` por grau abaixo de `-4.0 °C`, limitado a `-90s` ou `-15%` do base),
  ///   evitando que o primeiro lote passe do ponto.
  int predictCycleDuration({
    required int baseCalibratedSeconds,
    required double baselineTemp,
    required double peakTemp,
    double nominalChamberTemp = -1.0,
    double coldChamberThreshold = -4.0,
    double chamberWarmCoeff = 16.0,
    double chamberColdDiscountCoeff = 12.0,
    double heatLoadCoeff = 18.0,
    int minDurationSeconds = 300,
    int maxDurationSeconds = 3600,
  }) {
    final deltaT = max(0.0, peakTemp - baselineTemp);
    final heatLoadAdjustment = (deltaT * heatLoadCoeff).round();

    int chamberOffset = 0;
    if (baselineTemp > nominalChamberTemp) {
      chamberOffset = ((baselineTemp - nominalChamberTemp) * chamberWarmCoeff)
          .round();
    } else if (baselineTemp < coldChamberThreshold) {
      final maxColdDiscount = min(90, (baseCalibratedSeconds * 0.15).round());
      final rawDiscount =
          ((coldChamberThreshold - baselineTemp) * chamberColdDiscountCoeff)
              .round();
      chamberOffset = -min(maxColdDiscount, rawDiscount);
    }

    // Limita a compensação térmica inicial a +300s (5 min) para evitar saltos extremos em uma única abertura
    final totalOffset = (chamberOffset + heatLoadAdjustment).clamp(-90, 300);
    final total = baseCalibratedSeconds + totalOffset;
    return total.clamp(minDurationSeconds, maxDurationSeconds);
  }

  /// Calcula apenas o delta de compensação térmica dinâmica (em segundos) em relação ao tempo base calibrado.
  int calculateThermalCompensationSeconds({
    required int baseCalibratedSeconds,
    required double baselineTemp,
    required double peakTemp,
  }) {
    final predicted = predictCycleDuration(
      baseCalibratedSeconds: baseCalibratedSeconds,
      baselineTemp: baselineTemp,
      peakTemp: peakTemp,
    );
    return predicted - baseCalibratedSeconds;
  }

  /// 2. Calcula a penalidade de tempo por abertura prematura da porta do freezer durante a cristalização.
  /// [doorOpenSeconds]: tempo total que a porta permaneceu aberta.
  /// [tempRise]: quanto a temperatura interna subiu durante/após a abertura (T_pico - T_abriu).
  /// [roomTemp]: temperatura atual da sala (se > 24 °C, agrava a perda convectiva).
  int calculateDoorPenalty({
    required int doorOpenSeconds,
    required double tempRise,
    double? roomTemp,
    double airLossCoeff = 1.3,
    double compressorRecoveryPerDegree = 30.0,
    int maxPenaltySeconds = 360,
  }) {
    if (doorOpenSeconds <= 0 && tempRise <= 0) return 0;

    final roomFactor = (roomTemp != null && roomTemp > 24.0)
        ? (1.0 + ((roomTemp - 24.0) * 0.04)).clamp(1.0, 1.25)
        : 1.0;

    final convectiveLossSeconds =
        max(0, doorOpenSeconds) * airLossCoeff * roomFactor;
    final thermalRecoverySeconds =
        max(0.0, tempRise) * compressorRecoveryPerDegree;

    final totalPenalty =
        (convectiveLossSeconds + thermalRecoverySeconds).round();
    return totalPenalty.clamp(0, maxPenaltySeconds);
  }

  /// 3. Avalia se a abertura com freezer ocioso (`idle`) foi apenas uma inspeção rápida/esbarrão
  /// (sem carregar formas novas).
  bool isInspectionOnly({
    required int doorOpenSeconds,
    double tempRise = 0.0,
    int inspectionThresholdSeconds = 8,
  }) {
    // Se a temperatura subiu >= 2.0 °C (mesmo em abertura curta >= 1s), houve troca de calor real (carregamento)
    if (tempRise >= 2.0 && doorOpenSeconds >= 1) return false;
    return doorOpenSeconds > 0 && doorOpenSeconds <= inspectionThresholdSeconds;
  }

  /// 3.b Auto-reconhecimento inteligente de Retirada vs. Retirada + Reabastecimento quando o lote está pronto.
  /// Baseado na assinatura real dos 194 eventos de porta da fábrica:
  /// - Só Retirada: 9s a 21s com salto térmico moderado (< 2.3 °C).
  /// - Retirou + Abasteceu na mesma abertura: >= 22s OU salto térmico >= 2.3 °C (com porta aberta >= 12s).
  DoorReadyActionEnum classifyReadyDoorInteraction({
    required int doorOpenSeconds,
    required double tempRise,
    int quickCheckMaxSeconds = 7,
    int autoReloadMinSeconds = 22,
    double autoReloadMinTempRise = 2.3,
  }) {
    if (doorOpenSeconds <= quickCheckMaxSeconds && tempRise < 1.2) {
      return DoorReadyActionEnum.quickInspection;
    }

    if (doorOpenSeconds >= autoReloadMinSeconds ||
        (doorOpenSeconds >= 12 && tempRise >= autoReloadMinTempRise)) {
      return DoorReadyActionEnum.unloadAndReload;
    }

    return DoorReadyActionEnum.unloadOnly;
  }

  /// 3.c Atualiza a previsão do tempo de reação até abrir a porta (em segundos).
  /// Usado para avisar que o lote está pronto um pouco antes (ex: 10s antes, aos 11:50 de 12:00),
  /// para que o tempo de caminhada até abrir a porta feche exatamente o tempo alvo.
  int updatePredictedDoorLeadSeconds({
    required int currentLeadSeconds,
    required int observedReactionSeconds,
    double alpha = 0.25,
    int minLeadSeconds = 5,
    int maxLeadSeconds = 20,
  }) {
    // Ignora outliers (ex: operadora estava ocupada em outra bancada e demorou > 45s)
    if (observedReactionSeconds < 2 || observedReactionSeconds > 45) {
      return currentLeadSeconds.clamp(minLeadSeconds, maxLeadSeconds);
    }
    final next =
        (currentLeadSeconds * (1.0 - alpha) +
                observedReactionSeconds * alpha)
            .round();
    return next.clamp(minLeadSeconds, maxLeadSeconds);
  }

  /// 4. Atualiza o tempo base calibrado para os próximos lotes usando feedback em malha fechada.
  /// REGRA ESTRITA DEFINIDA PELO USUÁRIO:
  /// - 'autoOk' (timeout de 30s sem clicar) ou 'onPoint' após o ciclo já ter dado pronto:
  ///   NÃO altera a calibração! Tudo correu conforme o esperado.
  /// - 'onPoint' acionado ANTES do tempo (botão manual "Pronto" durante a cristalização):
  ///   Aproxima o tempo calibrado do tempo real executado.
  /// - 'soft' ("Ainda Mole"): Tempo foi insuficiente -> Incrementa o tempo calibrado (+8% ou min 90s).
  /// - 'overchilled' ("Muito Gelado"): Tempo foi longo demais -> Reduz o tempo calibrado (-5% ou min 60s).
  int adaptCalibration({
    required int currentCalibratedSeconds,
    required int executedEffectiveSeconds,
    required FreezerFeedbackEnum feedback,
    bool isEarlyManualReady = false,
    double learningRate = 0.20,
    int minDurationSeconds = 300,
    int maxDurationSeconds = 3600,
  }) {
    int updatedSeconds;

    switch (feedback) {
      case FreezerFeedbackEnum.autoOk:
        // Se deu pronto e ninguém reclamou nos 30s, estava tudo OK: nunca infla o tempo!
        return currentCalibratedSeconds.clamp(
          minDurationSeconds,
          maxDurationSeconds,
        );

      case FreezerFeedbackEnum.onPoint:
        // Só altera a calibração se o operador marcou manualmente como "Pronto" ANTES de terminar o tempo
        if (!isEarlyManualReady ||
            executedEffectiveSeconds >= currentCalibratedSeconds) {
          return currentCalibratedSeconds.clamp(
            minDurationSeconds,
            maxDurationSeconds,
          );
        }
        final diff = executedEffectiveSeconds - currentCalibratedSeconds;
        updatedSeconds =
            (currentCalibratedSeconds + (diff * learningRate)).round();
        break;

      case FreezerFeedbackEnum.soft:
        // Ovos moles = faltou resfriamento. Aumenta tempo base.
        final step = max(90, (currentCalibratedSeconds * 0.08).round());
        updatedSeconds = currentCalibratedSeconds + step;
        break;

      case FreezerFeedbackEnum.overchilled:
        // Ovos muito gelados / duros = passou do tempo. Reduz tempo base.
        final step = max(60, (currentCalibratedSeconds * 0.05).round());
        updatedSeconds = currentCalibratedSeconds - step;
        break;
    }

    return updatedSeconds.clamp(minDurationSeconds, maxDurationSeconds);
  }

  /// 5. Tempo de extensão imediata para o ciclo corrente caso o operador reporte 'Ainda Mole'.
  int immediateExtensionSeconds({required FreezerFeedbackEnum feedback}) {
    if (feedback == FreezerFeedbackEnum.soft) {
      return 180; // 3 minutos extras imediatos de resfriamento
    }
    return 0;
  }

  /// 6. Avalia se o freezer entrou no ciclo de degelo (Frost Free desligado / motor off).
  /// Regras blindadas contra falsos positivos e falsos negativos (baseadas nos dados reais da fábrica):
  /// - Gatilho A (Subida contínua com porta fechada): após a inércia pós-fechamento ([postDoorInertiaSeconds], 90s),
  ///   na janela de [windowSeconds], a temperatura subiu >= [minClosedDoorTempRise] (2.0 °C) desde a mínima da janela.
  /// - Gatilho B (Temperatura absoluta elevada sem queda): a temperatura permaneceu >= [highTempThreshold]
  ///   (5.5 °C) durante pelo menos [highTempSustainedSeconds] (180s) sem cair >= 0.4 °C.
  ///   Mesmo que a porta tenha sido aberta rapidamente no meio, se antes e depois da porta a câmara permaneceu
  ///   >= 5.5 °C por >= 300s sem conseguir baixar temperatura, reconhece a perda de rendimento/degelo.
  bool detectDefrostStart({
    required double currentTemp,
    required bool isDoorOpen,
    required DateTime now,
    DateTime? lastDoorCloseAt,
    required List<({DateTime timestamp, double temperature})> history,
    int postDoorInertiaSeconds = 90,
    int windowSeconds = 180,
    double minClosedDoorTempRise = 2.0,
    double highTempThreshold = 5.5,
    int highTempSustainedSeconds = 180,
  }) {
    if (isDoorOpen) return false;

    final secondsSinceDoorClose = lastDoorCloseAt != null
        ? now.difference(lastDoorCloseAt).inSeconds
        : 999999;

    if (secondsSinceDoorClose < postDoorInertiaSeconds) {
      return false;
    }

    // Filtra amostras ocorridas após o fim da inércia pós-porta
    final inertiaCutoff = lastDoorCloseAt?.add(
      Duration(seconds: postDoorInertiaSeconds),
    );
    final validSamples = history.where((pt) {
      if (inertiaCutoff != null && pt.timestamp.isBefore(inertiaCutoff)) {
        return false;
      }
      return true;
    }).toList();

    if (validSamples.length >= 3) {
      // Gatilho A: Subida contínua >= 2.0 °C na janela pós-inércia
      final windowCutoff = now.subtract(Duration(seconds: windowSeconds));
      final windowSamples = validSamples
          .where((pt) => !pt.timestamp.isBefore(windowCutoff))
          .toList();

      if (windowSamples.length >= 3) {
        final spanSeconds = now
            .difference(windowSamples.first.timestamp)
            .inSeconds;
        if (spanSeconds >= 60) {
          double minT = windowSamples.first.temperature;
          DateTime minTs = windowSamples.first.timestamp;
          double maxAfterMin = minT;

          for (final s in windowSamples) {
            if (s.temperature < minT) {
              minT = s.temperature;
              minTs = s.timestamp;
              maxAfterMin = s.temperature;
            } else if (s.temperature > maxAfterMin) {
              maxAfterMin = s.temperature;
            }
          }

          final riseFromMin = currentTemp - minT;
          final isStillRisingOrAtPeak = (maxAfterMin - currentTemp) <= 0.25;
          final riseDurationSec = now.difference(minTs).inSeconds;

          if (riseFromMin >= minClosedDoorTempRise &&
              isStillRisingOrAtPeak &&
              riseDurationSec >= 60) {
            return true;
          }
        }
      }

      // Gatilho B1: Temperatura >= 5.5 °C sustentada por >= 180s pós-inércia sem resfriar
      if (currentTemp >= highTempThreshold) {
        final sustainedCutoff = now.subtract(
          Duration(seconds: highTempSustainedSeconds),
        );
        final sustainedSamples = validSamples
            .where((pt) => !pt.timestamp.isBefore(sustainedCutoff))
            .toList();

        if (sustainedSamples.length >= 3) {
          final spanSec = now
              .difference(sustainedSamples.first.timestamp)
              .inSeconds;
          if (spanSec >= highTempSustainedSeconds - 15) {
            final allAboveThreshold = sustainedSamples.every(
              (s) => s.temperature >= highTempThreshold - 0.3,
            );
            final firstTemp = sustainedSamples.first.temperature;
            final notCoolingDown = (firstTemp - currentTemp) < 0.4;
            if (allAboveThreshold && notCoolingDown) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  /// 7. Avalia se o compressor do freezer religou e já está recuperando temperatura após o degelo.
  bool detectDefrostEnd({
    required double currentTemp,
    required double defrostPeakTemp,
    required bool hasActiveCycle,
    double minDropFromPeak = 1.0,
    double safeIdleReadyTemp = 2.5,
  }) {
    final dropFromPeak = defrostPeakTemp - currentTemp;
    if (dropFromPeak < minDropFromPeak) {
      return false;
    }

    if (!hasActiveCycle && currentTemp > safeIdleReadyTemp) {
      return false;
    }

    return true;
  }

  /// 8. Calcula o bônus de recuperação térmica (em segundos) somado ao alvo quando o motor religa
  /// após um degelo durante um lote ativo.
  int calculateDefrostRecoverySeconds({
    required double defrostStartTemp,
    required double defrostPeakTemp,
    double recoverySecondsPerDegree = 25.0,
    int minRecoverySeconds = 60,
    int maxRecoverySeconds = 420,
  }) {
    final deltaT = max(0.0, defrostPeakTemp - defrostStartTemp);
    if (deltaT <= 0.2) return minRecoverySeconds;
    final bonus = (deltaT * recoverySecondsPerDegree).round();
    return bonus.clamp(minRecoverySeconds, maxRecoverySeconds);
  }
}
