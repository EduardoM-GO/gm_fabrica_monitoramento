enum DoorAlertLevel {
  normal,
  warning,
  critical;

  bool get isNormal => this == DoorAlertLevel.normal;
  bool get isWarning => this == DoorAlertLevel.warning;
  bool get isCritical => this == DoorAlertLevel.critical;
}

enum FreezerBatchStatus {
  idle,
  cooling,
  ready,
  doorOpen,
  feedbackPending;

  bool get isIdle => this == FreezerBatchStatus.idle;
  bool get isCooling => this == FreezerBatchStatus.cooling;
  bool get isReady => this == FreezerBatchStatus.ready;
  bool get isDoorOpen => this == FreezerBatchStatus.doorOpen;
  bool get isFeedbackPending => this == FreezerBatchStatus.feedbackPending;
}

class TemperaturePoint {
  final DateTime timestamp;
  final double temperature;

  const TemperaturePoint({
    required this.timestamp,
    required this.temperature,
  });
}

class FreezerViewData {
  final String id;
  final String name;
  final double currentTemp;
  final bool isProbeOk;
  final bool isDoorOpen;
  final DateTime? doorStateSince;
  final double baselineTemp;
  final List<TemperaturePoint> history;
  final DoorAlertLevel alertLevel;

  // Batch monitoring & readiness estimation
  final FreezerBatchStatus batchStatus;
  final DateTime? batchStartedAt;
  final int targetCoolingMinutes;
  final int remainingSeconds;
  final int? feedbackCountdownSeconds;
  final String? lastFeedback;

  const FreezerViewData({
    required this.id,
    required this.name,
    required this.currentTemp,
    required this.isProbeOk,
    required this.isDoorOpen,
    this.doorStateSince,
    required this.baselineTemp,
    this.history = const [],
    this.alertLevel = DoorAlertLevel.normal,
    this.batchStatus = FreezerBatchStatus.idle,
    this.batchStartedAt,
    this.targetCoolingMinutes = 20,
    this.remainingSeconds = 1200,
    this.feedbackCountdownSeconds,
    this.lastFeedback,
  });

  /// Duration elapsed in the current door state (open or closed)
  Duration get doorDuration {
    if (doorStateSince == null) return Duration.zero;
    final diff = DateTime.now().difference(doorStateSince!);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Variation in temperature since the door entered current state:
  /// - When open: (current - baseline) -> positive value means warming up (loss of cold)
  /// - When closed: (current - baseline) -> negative value means cooling down (recovering cold)
  double get temperatureDelta => currentTemp - baselineTemp;

  /// Progress of cooling batch from 0.0 to 1.0
  double get batchProgress {
    final totalSec = targetCoolingMinutes * 60;
    if (totalSec <= 0) return 1.0;
    final elapsedSec = totalSec - remainingSeconds;
    return (elapsedSec / totalSec).clamp(0.0, 1.0);
  }

  /// Formatted remaining time mm:ss
  String get remainingFormatted {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  FreezerViewData copyWith({
    String? id,
    String? name,
    double? currentTemp,
    bool? isProbeOk,
    bool? isDoorOpen,
    DateTime? doorStateSince,
    double? baselineTemp,
    List<TemperaturePoint>? history,
    DoorAlertLevel? alertLevel,
    FreezerBatchStatus? batchStatus,
    DateTime? batchStartedAt,
    int? targetCoolingMinutes,
    int? remainingSeconds,
    int? feedbackCountdownSeconds,
    bool clearFeedbackCountdown = false,
    String? lastFeedback,
  }) {
    return FreezerViewData(
      id: id ?? this.id,
      name: name ?? this.name,
      currentTemp: currentTemp ?? this.currentTemp,
      isProbeOk: isProbeOk ?? this.isProbeOk,
      isDoorOpen: isDoorOpen ?? this.isDoorOpen,
      doorStateSince: doorStateSince ?? this.doorStateSince,
      baselineTemp: baselineTemp ?? this.baselineTemp,
      history: history ?? this.history,
      alertLevel: alertLevel ?? this.alertLevel,
      batchStatus: batchStatus ?? this.batchStatus,
      batchStartedAt: batchStartedAt ?? this.batchStartedAt,
      targetCoolingMinutes: targetCoolingMinutes ?? this.targetCoolingMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      feedbackCountdownSeconds: clearFeedbackCountdown
          ? null
          : (feedbackCountdownSeconds ?? this.feedbackCountdownSeconds),
      lastFeedback: lastFeedback ?? this.lastFeedback,
    );
  }
}

