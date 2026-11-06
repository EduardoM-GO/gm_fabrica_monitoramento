class FreezerTelemetryLogEntity {
  final String id;
  final String freezerId;
  final double temperature;
  final bool isDoorOpen;
  final bool isSensorOk;
  final DateTime recordedAt;
  final String? triggerReason; // 'event_door', 'event_probe', 'alert_temp', 'periodic_30s'
  final bool isSynced;

  const FreezerTelemetryLogEntity({
    required this.id,
    required this.freezerId,
    required this.temperature,
    required this.isDoorOpen,
    required this.isSensorOk,
    required this.recordedAt,
    this.triggerReason,
    required this.isSynced,
  });

  FreezerTelemetryLogEntity copyWith({
    String? id,
    String? freezerId,
    double? temperature,
    bool? isDoorOpen,
    bool? isSensorOk,
    DateTime? recordedAt,
    String? triggerReason,
    bool? isSynced,
  }) {
    return FreezerTelemetryLogEntity(
      id: id ?? this.id,
      freezerId: freezerId ?? this.freezerId,
      temperature: temperature ?? this.temperature,
      isDoorOpen: isDoorOpen ?? this.isDoorOpen,
      isSensorOk: isSensorOk ?? this.isSensorOk,
      recordedAt: recordedAt ?? this.recordedAt,
      triggerReason: triggerReason ?? this.triggerReason,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

