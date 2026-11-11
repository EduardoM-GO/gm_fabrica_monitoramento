enum AdjustmentReasonEnum {
  brokenShell('Casca quebrada'),
  weightDefect('Defeito no peso'),
  thermalDeformation('Deformação térmica'),
  manualCorrection('Correção manual'),
  other('Outros');

  final String label;
  const AdjustmentReasonEnum(this.label);
}
