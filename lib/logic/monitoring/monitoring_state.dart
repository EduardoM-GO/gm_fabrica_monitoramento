import '../../data/models/freezer_view_data.dart';
import '../../data/services/websocket_service.dart';

class MonitoringState {
  final ConnectionStatus connectionStatus;
  final String? connectionErrorMessage;
  final int uptimeMs;
  final int rawEggCount;
  final int batchEggCount;
  final int batchOffset;
  final double eggsPerMinute;
  final bool isHitAnimating;
  final FreezerViewData? freezer1;
  final FreezerViewData? freezer2;
  final DateTime? lastHitTime;
  final DateTime? lastTelemTime;

  // Box (Caixa) and Packaging metrics
  final int currentBoxCount;
  final int boxCapacity;
  final int completedBoxesCount;
  final int dailyTotalEggs;
  final bool isBoxJustCompleted;

  List<FreezerViewData> get activeFreezers => [
    ?freezer1,
    ?freezer2,
  ];

  const MonitoringState({
    this.connectionStatus = ConnectionStatus.disconnected,
    this.connectionErrorMessage,
    this.uptimeMs = 0,
    this.rawEggCount = 0,
    this.batchEggCount = 0,
    this.batchOffset = 0,
    this.eggsPerMinute = 0.0,
    this.isHitAnimating = false,
    this.freezer1,
    this.freezer2,
    this.lastHitTime,
    this.lastTelemTime,
    this.currentBoxCount = 0,
    this.boxCapacity = 50,
    this.completedBoxesCount = 0,
    this.dailyTotalEggs = 0,
    this.isBoxJustCompleted = false,
  });

  factory MonitoringState.initial({int defaultBoxCapacity = 50}) {
    return MonitoringState(
      connectionStatus: ConnectionStatus.disconnected,
      connectionErrorMessage: null,
      uptimeMs: 0,
      rawEggCount: 0,
      batchEggCount: 0,
      batchOffset: 0,
      eggsPerMinute: 0.0,
      isHitAnimating: false,
      freezer1: null,
      freezer2: null,
      currentBoxCount: 0,
      boxCapacity: defaultBoxCapacity,
      completedBoxesCount: 0,
      dailyTotalEggs: 0,
      isBoxJustCompleted: false,
    );
  }

  MonitoringState copyWith({
    ConnectionStatus? connectionStatus,
    String? connectionErrorMessage,
    bool clearError = false,
    int? uptimeMs,
    int? rawEggCount,
    int? batchEggCount,
    int? batchOffset,
    double? eggsPerMinute,
    bool? isHitAnimating,
    FreezerViewData? freezer1,
    FreezerViewData? freezer2,
    DateTime? lastHitTime,
    DateTime? lastTelemTime,
    int? currentBoxCount,
    int? boxCapacity,
    int? completedBoxesCount,
    int? dailyTotalEggs,
    bool? isBoxJustCompleted,
  }) {
    return MonitoringState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectionErrorMessage:
          clearError ? null : (connectionErrorMessage ?? this.connectionErrorMessage),
      uptimeMs: uptimeMs ?? this.uptimeMs,
      rawEggCount: rawEggCount ?? this.rawEggCount,
      batchEggCount: batchEggCount ?? this.batchEggCount,
      batchOffset: batchOffset ?? this.batchOffset,
      eggsPerMinute: eggsPerMinute ?? this.eggsPerMinute,
      isHitAnimating: isHitAnimating ?? this.isHitAnimating,
      freezer1: freezer1 ?? this.freezer1,
      freezer2: freezer2 ?? this.freezer2,
      lastHitTime: lastHitTime ?? this.lastHitTime,
      lastTelemTime: lastTelemTime ?? this.lastTelemTime,
      currentBoxCount: currentBoxCount ?? this.currentBoxCount,
      boxCapacity: boxCapacity ?? this.boxCapacity,
      completedBoxesCount: completedBoxesCount ?? this.completedBoxesCount,
      dailyTotalEggs: dailyTotalEggs ?? this.dailyTotalEggs,
      isBoxJustCompleted: isBoxJustCompleted ?? this.isBoxJustCompleted,
    );
  }
}
