enum BatchStatus {
  inProgress,
  paused,
  completed;

  bool get isInProgress => this == BatchStatus.inProgress;
  bool get isPaused => this == BatchStatus.paused;
  bool get isCompleted => this == BatchStatus.completed;
}

class ProductionBatchEntity {
  final String id;
  final String productId;
  final String productName;
  final double unitWeightGrams;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int initialHardwareCount;
  final int grossProducedCount; // Quantidade bruta contada pelo sensor
  final int discardedCount; // Quebras, descartes e defeitos
  final BatchStatus status;
  final bool isSynced;

  const ProductionBatchEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitWeightGrams,
    required this.startedAt,
    this.finishedAt,
    required this.initialHardwareCount,
    required this.grossProducedCount,
    required this.discardedCount,
    required this.status,
    required this.isSynced,
  });

  int get netProducedCount =>
      (grossProducedCount - discardedCount).clamp(0, 9999999);

  double get totalWeightKg => (netProducedCount * unitWeightGrams) / 1000.0;

  ProductionBatchEntity copyWith({
    String? id,
    String? productId,
    String? productName,
    double? unitWeightGrams,
    DateTime? startedAt,
    DateTime? finishedAt,
    int? initialHardwareCount,
    int? grossProducedCount,
    int? discardedCount,
    BatchStatus? status,
    bool? isSynced,
  }) {
    return ProductionBatchEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitWeightGrams: unitWeightGrams ?? this.unitWeightGrams,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      initialHardwareCount: initialHardwareCount ?? this.initialHardwareCount,
      grossProducedCount: grossProducedCount ?? this.grossProducedCount,
      discardedCount: discardedCount ?? this.discardedCount,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

