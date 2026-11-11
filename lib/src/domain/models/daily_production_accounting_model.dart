final class DailyProductionAccountingModel {
  final DateTime date;
  final int grossCount;
  final int discardsCount;
  final int netCount;
  final int completedBoxes;

  const DailyProductionAccountingModel({
    required this.date,
    required this.grossCount,
    required this.discardsCount,
    required this.netCount,
    required this.completedBoxes,
  });

  factory DailyProductionAccountingModel.zero(DateTime date) =>
      DailyProductionAccountingModel(
        date: date,
        grossCount: 0,
        discardsCount: 0,
        netCount: 0,
        completedBoxes: 0,
      );

  DailyProductionAccountingModel copyWith({
    DateTime? date,
    int? grossCount,
    int? discardsCount,
    int? netCount,
    int? completedBoxes,
  }) {
    return DailyProductionAccountingModel(
      date: date ?? this.date,
      grossCount: grossCount ?? this.grossCount,
      discardsCount: discardsCount ?? this.discardsCount,
      netCount: netCount ?? this.netCount,
      completedBoxes: completedBoxes ?? this.completedBoxes,
    );
  }
}

