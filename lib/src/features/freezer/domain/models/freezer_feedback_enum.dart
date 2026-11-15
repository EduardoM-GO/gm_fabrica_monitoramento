enum FreezerFeedbackEnum {
  onPoint('on_point', 'No Ponto'),
  soft('soft', 'Ainda Mole'),
  overchilled('overchilled', 'Muito Gelado / Duro'),
  autoOk('auto_ok', 'No Ponto (Automático)');

  final String code;
  final String label;
  const FreezerFeedbackEnum(this.code, this.label);

  static FreezerFeedbackEnum fromCode(String? code) {
    if (code == null) return FreezerFeedbackEnum.autoOk;
    return FreezerFeedbackEnum.values.firstWhere(
      (e) => e.code == code,
      orElse: () => FreezerFeedbackEnum.autoOk,
    );
  }
}

