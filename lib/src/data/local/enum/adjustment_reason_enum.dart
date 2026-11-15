enum AdjustmentReasonEnum {
  brokenShell('Casca quebrada'),
  weightDefect('Defeito no peso'),
  thermalDeformation('Deformação térmica'),
  manualCorrection('Correção manual'),
  other('Outros');

  final String label;
  const AdjustmentReasonEnum(this.label);

  /// Indica se o tipo de lançamento soma ovos à produção (ex: sensor não contou)
  /// em vez de subtrair como quebra/descarte.
  bool get isAddition => this == AdjustmentReasonEnum.manualCorrection;
}
