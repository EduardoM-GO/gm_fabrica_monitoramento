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
}
