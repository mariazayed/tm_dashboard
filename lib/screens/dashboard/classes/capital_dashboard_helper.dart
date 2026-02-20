import '../../../enums/capital_reason_enum.dart';
import '../../../models/capital_model.dart';
import 'summary_data.dart';
import 'weekly_breakdown.dart';

class CapitalDashboardHelper {
  final List<CapitalModel> capitals;

  CapitalDashboardHelper(this.capitals);

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get weekStart {
    final now = DateTime.now();
    final difference = now.weekday - DateTime.monday;
    final monday = now.subtract(Duration(days: difference));
    return DateTime(monday.year, monday.month, monday.day);
  }

  DateTime get monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  SummaryData summaryFrom(DateTime from) {
    final profits = _sum(from, CapitalReasonEnum.PROFIT);
    final losses = _sum(from, CapitalReasonEnum.LOSS);

    return SummaryData(profits: profits, losses: losses, pnl: profits + losses);
  }

  double _sum(DateTime from, CapitalReasonEnum reason) {
    return capitals
        .where((c) => !c.dateTime.isBefore(from))
        .where((c) => c.reason == reason)
        .fold(0.0, (a, b) => a + b.amount);
  }

  double get totalDeposits => capitals
      .where((c) => c.reason == CapitalReasonEnum.DEPOSIT)
      .fold(0.0, (a, b) => a + b.amount);

  double get totalWithdraws => capitals
      .where((c) => c.reason == CapitalReasonEnum.WITHDRAW)
      .fold(0.0, (a, b) => a + b.amount);

  List<MapEntry<DateTime, double>> weeklyPnl() {
    final Map<DateTime, double> weekly = {};

    for (final c in capitals) {
      if (c.reason != CapitalReasonEnum.PROFIT &&
          c.reason != CapitalReasonEnum.LOSS) {
        continue;
      }

      final monday = c.dateTime.subtract(
        Duration(days: c.dateTime.weekday - DateTime.monday),
      );

      final weekStart = DateTime(monday.year, monday.month, monday.day);

      weekly.update(
        weekStart,
        (value) => value + c.amount,
        ifAbsent: () => c.amount,
      );
    }

    final sorted = weekly.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return sorted;
  }

  List<WeeklyBreakdown> weeklyBreakdown() {
    final Map<DateTime, WeeklyBreakdown> weekly = {};

    for (final c in capitals) {
      if (c.reason != CapitalReasonEnum.PROFIT &&
          c.reason != CapitalReasonEnum.LOSS) {
        continue;
      }

      final monday = c.dateTime.subtract(
        Duration(days: c.dateTime.weekday - DateTime.monday),
      );

      final weekStart = DateTime(monday.year, monday.month, monday.day);

      weekly.putIfAbsent(
        weekStart,
        () => WeeklyBreakdown(weekStart: weekStart),
      );

      if (c.reason == CapitalReasonEnum.PROFIT) {
        weekly[weekStart]!.profit += c.amount;
      } else {
        weekly[weekStart]!.loss += c.amount;
      }
    }

    final list = weekly.values.toList()
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));

    return list;
  }
}
