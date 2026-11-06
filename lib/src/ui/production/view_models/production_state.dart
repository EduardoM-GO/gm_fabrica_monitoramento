import '../../../../data/model/telemetry_model.dart';
import '../../../../domain/entities/product_entity.dart';
import '../../../../domain/entities/production_batch_entity.dart';

export '../../../../data/model/telemetry_model.dart' show ConnectionStatus;
export '../../../../domain/entities/product_entity.dart';
export '../../../../domain/entities/production_batch_entity.dart';

/// Immutable UI state representing egg packaging production line.
class ProductionState {
  final ConnectionStatus connectionStatus;
  final String? connectionErrorMessage;
  final ProductionBatchEntity? activeBatch;
  final List<ProductEntity> availableProducts;
  final int currentBoxCount;
  final int boxCapacity;
  final int completedBoxesCount;
  final int dailyTotalEggs;
  final int uptimeMs;
  final double eggsPerMinute;
  final bool isHitAnimating;
  final bool isBoxJustCompleted;
  final int? lastRawHardwareCount;
  final DateTime? lastHitTime;
  final String? actionErrorMessage;

  int get batchGrossCount => activeBatch?.grossProducedCount ?? 0;
  int get batchDiscardedCount => activeBatch?.discardedCount ?? 0;
  int get batchNetCount => activeBatch?.netProducedCount ?? 0;
  double get batchTotalWeightKg => activeBatch?.totalWeightKg ?? 0.0;

  const ProductionState({
    this.connectionStatus = ConnectionStatus.disconnected,
    this.connectionErrorMessage,
    this.activeBatch,
    this.availableProducts = const [],
    this.currentBoxCount = 0,
    this.boxCapacity = 50,
    this.completedBoxesCount = 0,
    this.dailyTotalEggs = 0,
    this.uptimeMs = 0,
    this.eggsPerMinute = 0.0,
    this.isHitAnimating = false,
    this.isBoxJustCompleted = false,
    this.lastRawHardwareCount,
    this.lastHitTime,
    this.actionErrorMessage,
  });

  factory ProductionState.initial({int defaultBoxCapacity = 50}) {
    return ProductionState(
      connectionStatus: ConnectionStatus.disconnected,
      boxCapacity: defaultBoxCapacity,
    );
  }

  ProductionState copyWith({
    ConnectionStatus? connectionStatus,
    String? connectionErrorMessage,
    bool clearConnectionError = false,
    ProductionBatchEntity? activeBatch,
    bool clearActiveBatch = false,
    List<ProductEntity>? availableProducts,
    int? currentBoxCount,
    int? boxCapacity,
    int? completedBoxesCount,
    int? dailyTotalEggs,
    int? uptimeMs,
    double? eggsPerMinute,
    bool? isHitAnimating,
    bool? isBoxJustCompleted,
    int? lastRawHardwareCount,
    DateTime? lastHitTime,
    String? actionErrorMessage,
    bool clearActionError = false,
  }) {
    return ProductionState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      connectionErrorMessage: clearConnectionError
          ? null
          : (connectionErrorMessage ?? this.connectionErrorMessage),
      activeBatch: clearActiveBatch ? null : (activeBatch ?? this.activeBatch),
      availableProducts: availableProducts ?? this.availableProducts,
      currentBoxCount: currentBoxCount ?? this.currentBoxCount,
      boxCapacity: boxCapacity ?? this.boxCapacity,
      completedBoxesCount: completedBoxesCount ?? this.completedBoxesCount,
      dailyTotalEggs: dailyTotalEggs ?? this.dailyTotalEggs,
      uptimeMs: uptimeMs ?? this.uptimeMs,
      eggsPerMinute: eggsPerMinute ?? this.eggsPerMinute,
      isHitAnimating: isHitAnimating ?? this.isHitAnimating,
      isBoxJustCompleted: isBoxJustCompleted ?? this.isBoxJustCompleted,
      lastRawHardwareCount: lastRawHardwareCount ?? this.lastRawHardwareCount,
      lastHitTime: lastHitTime ?? this.lastHitTime,
      actionErrorMessage: clearActionError
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
    );
  }
}
