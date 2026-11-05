class SettingsState {
  final String wsUrl;
  final int doorWarningSeconds;
  final int doorCriticalSeconds;
  final bool eggSoundEnabled;
  final bool alarmSoundEnabled;
  final bool isMockEnabled;
  final int defaultBoxCapacity;
  final int freezer1BaseMinutes;
  final int freezer2BaseMinutes;
  final int doorInspectionThresholdSeconds;

  const SettingsState({
    this.wsUrl = 'ws://192.168.0.58:81',
    this.doorWarningSeconds = 30,
    this.doorCriticalSeconds = 60,
    this.eggSoundEnabled = true,
    this.alarmSoundEnabled = true,
    this.isMockEnabled = false,
    this.defaultBoxCapacity = 50,
    this.freezer1BaseMinutes = 20,
    this.freezer2BaseMinutes = 15,
    this.doorInspectionThresholdSeconds = 15,
  });

  SettingsState copyWith({
    String? wsUrl,
    int? doorWarningSeconds,
    int? doorCriticalSeconds,
    bool? eggSoundEnabled,
    bool? alarmSoundEnabled,
    bool? isMockEnabled,
    int? defaultBoxCapacity,
    int? freezer1BaseMinutes,
    int? freezer2BaseMinutes,
    int? doorInspectionThresholdSeconds,
  }) {
    return SettingsState(
      wsUrl: wsUrl ?? this.wsUrl,
      doorWarningSeconds: doorWarningSeconds ?? this.doorWarningSeconds,
      doorCriticalSeconds: doorCriticalSeconds ?? this.doorCriticalSeconds,
      eggSoundEnabled: eggSoundEnabled ?? this.eggSoundEnabled,
      alarmSoundEnabled: alarmSoundEnabled ?? this.alarmSoundEnabled,
      isMockEnabled: isMockEnabled ?? this.isMockEnabled,
      defaultBoxCapacity: defaultBoxCapacity ?? this.defaultBoxCapacity,
      freezer1BaseMinutes: freezer1BaseMinutes ?? this.freezer1BaseMinutes,
      freezer2BaseMinutes: freezer2BaseMinutes ?? this.freezer2BaseMinutes,
      doorInspectionThresholdSeconds:
          doorInspectionThresholdSeconds ?? this.doorInspectionThresholdSeconds,
    );
  }
}
