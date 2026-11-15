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

  final int expectedDurationSeconds;
  final int remainingSeconds;
  final int accumulatedPenaltySeconds;
  final int accumulatedDoorOpenSeconds;
  final int doorOpenCount;

  final int? feedbackCountdownSeconds;
  final FreezerFeedbackEnum? lastFeedback;
  final String? activeCycleId;

  final List<({DateTime timestamp, double temperature})> temperatureHistory;
  final bool isCalibrated;
  final int calibratedBaseSeconds;

  const FreezerLiveState({
    required this.freezerId,
    required this.name,
    required this.currentTemp,
    required this.isDoorOpen,
    required this.isSensorOk,
    required this.status,
    this.baselineTemp,
    this.peakTemp,
    required this.expectedDurationSeconds,
    required this.remainingSeconds,
    this.accumulatedPenaltySeconds = 0,
    this.accumulatedDoorOpenSeconds = 0,
    this.doorOpenCount = 0,
    this.feedbackCountdownSeconds,
    this.lastFeedback,
    this.activeCycleId,
    this.temperatureHistory = const [],
    this.isCalibrated = false,
    this.calibratedBaseSeconds = 1200,
  });

  double get progress {
    if (expectedDurationSeconds <= 0) return 0.0;
    final elapsed = expectedDurationSeconds - remainingSeconds;
    return (elapsed / expectedDurationSeconds).clamp(0.0, 1.0);
  }

  String get remainingFormatted {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
    bool? isCalibrated,
    int? calibratedBaseSeconds,
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
      isCalibrated: isCalibrated ?? this.isCalibrated,
      calibratedBaseSeconds:
          calibratedBaseSeconds ?? this.calibratedBaseSeconds,
    );
  }
}

