enum AdjustmentReason {
  brokenShell, // Casca quebrada
  weightDefect, // Fora do peso padrão
  thermalDeform, // Derretido/Deformado
  manualCorrection; // Correção manual de contagem

  String get label {
    switch (this) {
      case AdjustmentReason.brokenShell:
        return 'Casca Quebrada';
      case AdjustmentReason.weightDefect:
        return 'Defeito de Peso';
      case AdjustmentReason.thermalDeform:
        return 'Deformação Térmica';
      case AdjustmentReason.manualCorrection:
        return 'Correção Manual';
    }
  }

  static AdjustmentReason fromString(String val) {
    return AdjustmentReason.values.firstWhere(
      (e) => e.name == val,
      orElse: () => AdjustmentReason.manualCorrection,
    );
  }
}

class BatchAdjustmentEntity {
  final String id;
  final String batchId;
  final AdjustmentReason reason;
  final String? customNote;
  final int deltaQuantity; // Ex: -3 (subtração)
  final DateTime createdAt;
  final bool isSynced;

  const BatchAdjustmentEntity({
    required this.id,
    required this.batchId,
    required this.reason,
    this.customNote,
    required this.deltaQuantity,
    required this.createdAt,
    required this.isSynced,
  });

  BatchAdjustmentEntity copyWith({
    String? id,
    String? batchId,
    AdjustmentReason? reason,
    String? customNote,
    int? deltaQuantity,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return BatchAdjustmentEntity(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      reason: reason ?? this.reason,
      customNote: customNote ?? this.customNote,
      deltaQuantity: deltaQuantity ?? this.deltaQuantity,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

