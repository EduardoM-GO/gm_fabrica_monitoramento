import 'dart:math';

import '../models/freezer_feedback_enum.dart';

/// Motor matemático e termodinâmico para estimativa, penalização
/// e aprendizado contínuo (closed-loop) do tempo ideal de resfriamento.
final class FreezerAdaptiveEngine {
  const FreezerAdaptiveEngine();

  /// 1. Estima a duração total do ciclo baseada no tempo calibrado e na carga térmica introduzida.
  /// [peakTemp] é a temperatura máxima atingida após o fechamento da porta.
  /// [baselineTemp] é a temperatura que o freezer operava antes da abertura/carga.
  int predictCycleDuration({
    required int baseCalibratedSeconds,
    required double baselineTemp,
    required double peakTemp,
    double heatLoadCoeff = 18.0, // segundos adicionais por °C de salto térmico
    int minDurationSeconds = 300, // 5 min mínimo
    int maxDurationSeconds = 3600, // 60 min máximo
  }) {
    final deltaT = max(0.0, peakTemp - baselineTemp);
    final heatLoadAdjustment = (deltaT * heatLoadCoeff).round();

    final total = baseCalibratedSeconds + heatLoadAdjustment;
    return total.clamp(minDurationSeconds, maxDurationSeconds);
  }

  /// 2. Calcula a penalidade de tempo por abertura prematura da porta do freezer.
  /// [doorOpenSeconds]: tempo total que a porta permaneceu aberta.
  /// [tempRise]: quanto a temperatura interna subiu durante a abertura (T_fechou - T_abriu).
  /// [compressorRecoveryPerDegree]: segundos necessários para o compressor resfriar 1°C.
  int calculateDoorPenalty({
    required int doorOpenSeconds,
    required double tempRise,
    double airLossCoeff = 1.3,
    double compressorRecoveryPerDegree = 30.0,
    int maxPenaltySeconds = 360, // Limite de 6 minutos de penalidade por evento
  }) {
    if (doorOpenSeconds <= 0 && tempRise <= 0) return 0;

    final convectiveLossSeconds = max(0, doorOpenSeconds) * airLossCoeff;
    final thermalRecoverySeconds = max(0.0, tempRise) * compressorRecoveryPerDegree;

    final totalPenalty = (convectiveLossSeconds + thermalRecoverySeconds).round();
    return totalPenalty.clamp(0, maxPenaltySeconds);
  }

  /// 3. Avalia se a abertura foi apenas uma inspeção rápida de rotina
  /// (ex: verificar visualmente sem descarregar nem carregar formas novas).
  bool isInspectionOnly({
    required int doorOpenSeconds,
    int inspectionThresholdSeconds = 12,
  }) {
    return doorOpenSeconds > 0 && doorOpenSeconds <= inspectionThresholdSeconds;
  }

  /// 4. Atualiza o tempo base calibrado para os próximos lotes usando feedback em malha fechada.
  /// - 'onPoint' / 'autoOk': Aproxima o tempo calibrado do tempo executado efetivo (EMA).
  /// - 'soft': Tempo foi insuficiente. Incrementa o tempo calibrado (+8% ou min 90s).
  /// - 'overchilled': Tempo foi longo demais. Reduz o tempo calibrado (-5% ou min 60s).
  int adaptCalibration({
    required int currentCalibratedSeconds,
    required int executedEffectiveSeconds,
    required FreezerFeedbackEnum feedback,
    double learningRate = 0.12,
    int minDurationSeconds = 300,
    int maxDurationSeconds = 3600,
  }) {
    int updatedSeconds;

    switch (feedback) {
      case FreezerFeedbackEnum.onPoint:
      case FreezerFeedbackEnum.autoOk:
        // Média Móvel Exponencial (EMA) suave aproximando do tempo real
        final diff = executedEffectiveSeconds - currentCalibratedSeconds;
        updatedSeconds = (currentCalibratedSeconds + (diff * learningRate)).round();
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
  /// Regras blindadas contra falsos positivos (baseadas nos dados reais da fábrica):
  /// - A porta deve estar fechada e ter respeitado o período de inércia pós-fechamento ([postDoorInertiaSeconds], padrão 90s).
  /// - Gatilho A (Subida contínua com porta fechada): na janela de [windowSeconds] (após a inércia),
  ///   a temperatura subiu >= [minClosedDoorTempRise] (padrão 2.0 °C) desde a mínima da janela
  ///   e não caiu mais que 0.25 °C do pico recente.
  /// - Gatilho B (Temperatura absoluta elevada sem queda): a temperatura permaneceu >= [highTempThreshold]
  ///   (padrão 5.5 °C) durante pelo menos [highTempSustainedSeconds] (padrão 180s) sem cair >= 0.4 °C.
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

    if (lastDoorCloseAt != null &&
        now.difference(lastDoorCloseAt).inSeconds < postDoorInertiaSeconds) {
      return false;
    }

    // Filtra apenas amostras ocorridas após o fim da inércia pós-porta
    final inertiaCutoff = lastDoorCloseAt?.add(
      Duration(seconds: postDoorInertiaSeconds),
    );
    final validSamples = history.where((pt) {
      if (inertiaCutoff != null && pt.timestamp.isBefore(inertiaCutoff)) {
        return false;
      }
      return true;
    }).toList();

    if (validSamples.length < 3) return false;

    // Gatilho A: Subida contínua >= 2.0 °C na janela (ex: últimos 3 min pós-inércia)
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

    // Gatilho B: Temperatura >= 5.5 °C sustentada por >= 180s sem resfriar
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

    return false;
  }

  /// 7. Avalia se o compressor do freezer religou e já está recuperando temperatura após o degelo.
  /// - Se o freezer tem um ciclo ativo ([hasActiveCycle] = true): destrava o ciclo assim que
  ///   a temperatura cair >= [minDropFromPeak] (padrão 1.0 °C) abaixo do pico atingido no degelo ([defrostPeakTemp]).
  /// - Se o freezer estava vazio/ocioso ([hasActiveCycle] = false): além de cair >= 1.0 °C do pico,
  ///   exige que a temperatura já tenha baixado para <= [safeIdleReadyTemp] (padrão +2.5 °C) antes de liberar "Aguardando Forminhas".
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
  /// após um degelo durante um lote ativo, compensando os graus que a câmara subiu enquanto esteve desligada.
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
