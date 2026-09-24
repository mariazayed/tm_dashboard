import '../../../enums/capital_reason_enum.dart';
import '../../../models/capital_model.dart';
import 'summary_data.dart';
import 'weekly_breakdown.dart';

class CapitalDashboardHelper {
  final List<CapitalModel> capitals;

  CapitalDashboardHelper(this.capitals);

  List<MapEntry<DateTime, double>>? _capitalOverTime;
  List<MapEntry<DateTime, double>>? _weeklyPnl;
  List<WeeklyBreakdown>? _weeklyBreakdown;
  double? _totalDeposits;
  double? _totalWithdraws;

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

  double get totalDeposits {
    final cached = _totalDeposits;
    if (cached != null) return cached;

    final total = capitals
        .where((c) => c.reason == CapitalReasonEnum.DEPOSIT)
        .fold<double>(0.0, (a, b) => a + b.amount);
    _totalDeposits = total;
    return total;
  }

  double get totalWithdraws {
    final cached = _totalWithdraws;
    if (cached != null) return cached;

    final total = capitals
        .where((c) => c.reason == CapitalReasonEnum.WITHDRAW)
        .fold<double>(0.0, (a, b) => a + b.amount);
    _totalWithdraws = total;
    return total;
  }

  /// Chronological running balance of the account: every capital record
  /// (deposits, withdrawals, and trade profit/loss) applied in dateTime
  /// order, so this is the *actual* capital curve — as opposed to
  /// [weeklyPnl] which only nets PROFIT/LOSS per week and ignores
  /// deposits/withdrawals.
  ///
  /// Sign convention: PROFIT and LOSS amounts already arrive signed from
  /// the server (LOSS is a negative pnl), and DEPOSIT amounts are entered
  /// as positive additions to capital, so those three are applied as-is.
  /// WITHDRAW amounts are entered as a positive magnitude (see the
  /// deposit/withdraw dialog on the dashboard), so they're subtracted here.
  List<MapEntry<DateTime, double>> capitalOverTime() {
    final cached = _capitalOverTime;
    if (cached != null) return cached;
    if (capitals.isEmpty) return [];

    final sorted = List<CapitalModel>.from(capitals)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    double running = 0;
    final List<MapEntry<DateTime, double>> points = [];

    for (final c in sorted) {
      final signedAmount = c.reason == CapitalReasonEnum.WITHDRAW
          ? -c.amount
          : c.amount;
      running += signedAmount;
      points.add(MapEntry(c.dateTime, running));
    }

    _capitalOverTime = points;
    return points;
  }

  /// The account's current capital — the last point of [capitalOverTime],
  /// or 0 if there's no capital history yet.
  double get currentCapital {
    final points = capitalOverTime();
    return points.isEmpty ? 0 : points.last.value;
  }

  List<MapEntry<DateTime, double>> weeklyPnl() {
    final cached = _weeklyPnl;
    if (cached != null) return cached;

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

    _weeklyPnl = sorted;
    return sorted;
  }

  List<WeeklyBreakdown> weeklyBreakdown() {
    final cached = _weeklyBreakdown;
    if (cached != null) return cached;

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

    _weeklyBreakdown = list;
    return list;
  }
}
