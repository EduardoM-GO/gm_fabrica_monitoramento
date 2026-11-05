import '../../data/models/freezer_view_data.dart';
import '../../data/services/websocket_service.dart';

class FreezerState {
  final ConnectionStatus connectionStatus;
  final FreezerViewData? freezer1;
  final FreezerViewData? freezer2;
  final DateTime? lastTelemTime;
  final bool hasThermalAnomaly;
  final String? thermalAnomalyMessage;

  List<FreezerViewData> get activeFreezers => [
        ?freezer1,
        ?freezer2,
      ];

  const FreezerState({
    this.connectionStatus = ConnectionStatus.disconnected,
    this.freezer1,
    this.freezer2,
    this.lastTelemTime,
    this.hasThermalAnomaly = false,
    this.thermalAnomalyMessage,
  });

  factory FreezerState.initial() {
    return const FreezerState(
      connectionStatus: ConnectionStatus.disconnected,
      freezer1: null,
      freezer2: null,
    );
  }

  FreezerState copyWith({
    ConnectionStatus? connectionStatus,
    FreezerViewData? freezer1,
    FreezerViewData? freezer2,
    DateTime? lastTelemTime,
    bool? hasThermalAnomaly,
    String? thermalAnomalyMessage,
    bool clearThermalAnomaly = false,
  }) {
    return FreezerState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      freezer1: freezer1 ?? this.freezer1,
      freezer2: freezer2 ?? this.freezer2,
      lastTelemTime: lastTelemTime ?? this.lastTelemTime,
      hasThermalAnomaly: clearThermalAnomaly
          ? false
          : (hasThermalAnomaly ?? this.hasThermalAnomaly),
      thermalAnomalyMessage: clearThermalAnomaly
          ? null
          : (thermalAnomalyMessage ?? this.thermalAnomalyMessage),
    );
  }
}
