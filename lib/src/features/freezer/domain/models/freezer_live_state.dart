import 'dart:math';

import 'freezer_feedback_enum.dart';
import 'freezer_status_enum.dart';

final class FreezerLiveState {
  final String freezerId;
  final String name;
  final double currentTemp;
  final bool isDoorOpen;
  final bool isSensorOk;
  final FreezerStatusEnum status;

  final double? baselineTemp;
  final double? peakTemp;
  final double? lastDoorOpenTemp;
  final double? lastDoorCloseTemp;

  final int expectedDurationSeconds;
  final int remainingSeconds;
  final int accumulatedPenaltySeconds;
  final int accumulatedDoorOpenSeconds;
  final int doorOpenCount;

  final int? feedbackCountdownSeconds;
  final FreezerFeedbackEnum? lastFeedback;
  final String? activeCycleId;

  final List<({DateTime timestamp, double temperature})> temperatureHistory;
  final List<({DateTime timestamp, bool isOpen, double temperature})>
  doorTransitions;
  final bool isCalibrated;
  final int calibratedBaseSeconds;
  final int unloadMinSeconds;
  final int reloadMinSeconds;

  const FreezerLiveState({
    required this.freezerId,
    required this.name,
    required this.currentTemp,
    required this.isDoorOpen,
    required this.isSensorOk,
    required this.status,
    this.baselineTemp,
    this.peakTemp,
    this.lastDoorOpenTemp,
    this.lastDoorCloseTemp,
    required this.expectedDurationSeconds,
    required this.remainingSeconds,
    this.accumulatedPenaltySeconds = 0,
    this.accumulatedDoorOpenSeconds = 0,
    this.doorOpenCount = 0,
    this.feedbackCountdownSeconds,
    this.lastFeedback,
    this.activeCycleId,
    this.temperatureHistory = const [],
    this.doorTransitions = const [],
    this.isCalibrated = false,
    this.calibratedBaseSeconds = 1200,
    this.unloadMinSeconds = 30,
    this.reloadMinSeconds = 60,
  });

  /// Segundos já decorridos no ciclo atual (0 quando em repouso).
  int get elapsedSeconds {
    if (status == FreezerStatusEnum.idle) return 0;
    return (expectedDurationSeconds - remainingSeconds).clamp(
      0,
      expectedDurationSeconds,
    );
  }

  double get progress {
    if (expectedDurationSeconds <= 0 || status == FreezerStatusEnum.idle) {
      return 0.0;
    }
    return (elapsedSeconds / expectedDurationSeconds).clamp(0.0, 1.0);
  }

  /// Tempo decorrido formatado (MM:SS), ex.: "08:30".
  String get elapsedFormatted {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Tempo alvo total formatado (MM:SS), ex.: "20:00".
  String get targetFormatted {
    final m = expectedDurationSeconds ~/ 60;
    final s = expectedDurationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get remainingFormatted {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Temperatura de referência antes da abertura de porta ou início de ciclo.
  double get effectiveBaselineTemp =>
      baselineTemp ??
      lastDoorOpenTemp ??
      (temperatureHistory.isNotEmpty
          ? temperatureHistory.first.temperature
          : currentTemp);

  /// Pico térmico registrado durante/após abertura da porta.
  double get effectivePeakTemp {
    final candidates = <double>[
      currentTemp,
      ?peakTemp,
      ?lastDoorCloseTemp,
      ?lastDoorOpenTemp,
    ];
    return candidates.reduce(max);
  }

  /// Variação de temperatura (ΔT) provocada pela abertura/fechamento da porta.
  double get doorDeltaTemp {
    final openTemp = lastDoorOpenTemp;
    if (openTemp == null) return 0.0;
    if (isDoorOpen) {
      return currentTemp - openTemp;
    }
    final peak = peakTemp ?? lastDoorCloseTemp ?? currentTemp;
    return peak - openTemp;
  }

  /// Percentual de recuperação térmica (0.0 a 1.0) após fechamento da porta.
  /// Retorna null se não houve elevação térmica relevante (> 0.2 °C).
  double? get thermalRecoveryProgress {
    if (isDoorOpen) return null;
    final base = lastDoorOpenTemp ?? baselineTemp;
    if (base == null || (lastDoorOpenTemp == null && peakTemp == null)) {
      return null;
    }
    final peak = effectivePeakTemp;
    final totalRise = peak - base;
    if (totalRise <= 0.2) return null;

    final recovered = peak - currentTemp;
    return (recovered / totalRise).clamp(0.0, 1.0);
  }

  FreezerLiveState copyWith({
    String? freezerId,
    String? name,
    double? currentTemp,
    bool? isDoorOpen,
    bool? isSensorOk,
    FreezerStatusEnum? status,
    double? baselineTemp,
    double? peakTemp,
    double? lastDoorOpenTemp,
    double? lastDoorCloseTemp,
    int? expectedDurationSeconds,
    int? remainingSeconds,
    int? accumulatedPenaltySeconds,
    int? accumulatedDoorOpenSeconds,
    int? doorOpenCount,
    int? feedbackCountdownSeconds,
    bool clearFeedbackCountdown = false,
    FreezerFeedbackEnum? lastFeedback,
    String? activeCycleId,
    bool clearActiveCycleId = false,
    List<({DateTime timestamp, double temperature})>? temperatureHistory,
    List<({DateTime timestamp, bool isOpen, double temperature})>?
    doorTransitions,
    bool? isCalibrated,
    int? calibratedBaseSeconds,
    int? unloadMinSeconds,
    int? reloadMinSeconds,
  }) {
    return FreezerLiveState(
      freezerId: freezerId ?? this.freezerId,
      name: name ?? this.name,
      currentTemp: currentTemp ?? this.currentTemp,
      isDoorOpen: isDoorOpen ?? this.isDoorOpen,
      isSensorOk: isSensorOk ?? this.isSensorOk,
      status: status ?? this.status,
      baselineTemp: baselineTemp ?? this.baselineTemp,
      peakTemp: peakTemp ?? this.peakTemp,
      lastDoorOpenTemp: lastDoorOpenTemp ?? this.lastDoorOpenTemp,
      lastDoorCloseTemp: lastDoorCloseTemp ?? this.lastDoorCloseTemp,
      expectedDurationSeconds:
          expectedDurationSeconds ?? this.expectedDurationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      accumulatedPenaltySeconds:
          accumulatedPenaltySeconds ?? this.accumulatedPenaltySeconds,
      accumulatedDoorOpenSeconds:
          accumulatedDoorOpenSeconds ?? this.accumulatedDoorOpenSeconds,
      doorOpenCount: doorOpenCount ?? this.doorOpenCount,
      feedbackCountdownSeconds: clearFeedbackCountdown
          ? null
          : (feedbackCountdownSeconds ?? this.feedbackCountdownSeconds),
      lastFeedback: lastFeedback ?? this.lastFeedback,
      activeCycleId: clearActiveCycleId
          ? null
          : (activeCycleId ?? this.activeCycleId),
      temperatureHistory: temperatureHistory ?? this.temperatureHistory,
      doorTransitions: doorTransitions ?? this.doorTransitions,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      calibratedBaseSeconds:
          calibratedBaseSeconds ?? this.calibratedBaseSeconds,
      unloadMinSeconds: unloadMinSeconds ?? this.unloadMinSeconds,
      reloadMinSeconds: reloadMinSeconds ?? this.reloadMinSeconds,
    );
  }

  @override
  String toString() =>
      'FreezerLiveState(name: $name, status: $status, currentTemp: $currentTemp, isDoorOpen: $isDoorOpen, isSensorOk: $isSensorOk, baselineTemp: $baselineTemp, peakTemp: $peakTemp, lastDoorOpenTemp: $lastDoorOpenTemp, lastDoorCloseTemp: $lastDoorCloseTemp, expectedDurationSeconds: $expectedDurationSeconds, remainingSeconds: $remainingSeconds, accumulatedPenaltySeconds: $accumulatedPenaltySeconds, accumulatedDoorOpenSeconds: $accumulatedDoorOpenSeconds, doorOpenCount: $doorOpenCount, feedbackCountdownSeconds: $feedbackCountdownSeconds, lastFeedback: $lastFeedback, activeCycleId: $activeCycleId, temperatureHistory: $temperatureHistory, isCalibrated: $isCalibrated, calibratedBaseSeconds: $calibratedBaseSeconds)';
}
