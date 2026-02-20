class WeeklyBreakdown {
  final DateTime weekStart;
  double profit = 0;
  double loss = 0;

  WeeklyBreakdown({required this.weekStart});

  double get net => profit + loss;
}
