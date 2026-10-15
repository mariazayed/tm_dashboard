import '../../../models/invest/contribution_model.dart';
import '../../../models/invest/contribution_status_model.dart';
import '../../../models/invest/insights_model.dart';
import '../../../models/invest/invest_settings_model.dart';
import '../../../models/invest/journal_model.dart';
import '../../../models/invest/learning_model.dart';
import '../../../models/invest/performance_model.dart';
import '../../../models/invest/plan_model.dart';
import '../../../models/invest/rule_check_model.dart';

/// Pure derivations behind the charts on the Charts screen. Nothing here
/// touches the network or the widget tree, so each one is unit-tested.

String monthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

DateTime monthStart(String key) =>
    DateTime(int.parse(key.substring(0, 4)), int.parse(key.substring(5, 7)));

/// The last [count] month keys ending with [now]'s month, oldest first.
List<String> lastMonths(DateTime now, int count) => [
  for (var i = count - 1; i >= 0; i--)
    monthKey(DateTime(now.year, now.month - i)),
];

List<ContributionModel> _byDate(List<ContributionModel> list) =>
    [...list]..sort((a, b) => a.contributedOn.compareTo(b.contributedOn));

/// The price, shares and average cost implied at each point of the value series.
class PricePoint {
  const PricePoint({
    required this.date,
    required this.shares,
    required this.price,
    required this.avgCost,
  });

  final DateTime date;
  final double shares;

  /// Value divided by shares held on that day.
  final double price;

  /// Amount put in divided by shares held on that day.
  final double avgCost;
}

/// Price and average cost per share on every day of [series]. Days before the
/// first buy have no shares and are left out.
List<PricePoint> pricePoints(
  List<SeriesPoint> series,
  List<ContributionModel> contributions,
) {
  final buys = _byDate(contributions);
  final points = [...series]..sort((a, b) => a.date.compareTo(b.date));
  final out = <PricePoint>[];
  var shares = 0.0;
  var next = 0;
  for (final p in points) {
    while (next < buys.length && !buys[next].contributedOn.isAfter(p.date)) {
      shares += buys[next].shares;
      next++;
    }
    if (shares <= 0) continue;
    out.add(
      PricePoint(
        date: p.date,
        shares: shares,
        price: p.valueCents / 100 / shares,
        avgCost: p.investedCents / 100 / shares,
      ),
    );
  }
  return out;
}

/// A running total at a date.
class DatedValue {
  const DatedValue(this.date, this.value);

  final DateTime date;
  final double value;
}

/// Fees paid so far, in currency units, stepping up at each buy.
List<DatedValue> feesRunning(List<ContributionModel> contributions) {
  var total = 0;
  return [
    for (final c in _byDate(contributions))
      DatedValue(c.contributedOn, (total += c.feeCents) / 100),
  ];
}

/// Shares owned so far, stepping up at each buy.
List<DatedValue> sharesOwned(List<ContributionModel> contributions) {
  var total = 0.0;
  return [
    for (final c in _byDate(contributions))
      DatedValue(c.contributedOn, total += c.shares),
  ];
}

/// One month of the plan against what happened.
class MonthPlan {
  const MonthPlan({
    required this.month,
    required this.state,
    required this.actualCents,
    required this.plannedCents,
  });

  final String month;
  final MonthState state;
  final int actualCents;
  final int plannedCents;

  int get differenceCents => actualCents - plannedCents;
}

/// Planned against actual per month. The month still waiting for its buy day
/// is left out: it is neither on plan nor off it yet.
List<MonthPlan> plannedVsActual(
  ContributionStatusModel status,
  InvestSettingsModel settings,
) => [
  for (final m in status.months)
    if (m.state != MonthState.pending)
      MonthPlan(
        month: m.month,
        state: m.state,
        actualCents: m.totalCents,
        plannedCents: settings.monthlyAmountCents,
      ),
];

/// Every buy with how many days after (positive) or before (negative) the
/// planned buy day of its month it happened.
class BuyTiming {
  const BuyTiming(this.date, this.daysAfter);

  final DateTime date;
  final int daysAfter;
}

List<BuyTiming> buyTiming(
  List<ContributionModel> contributions,
  InvestSettingsModel settings,
) => [
  for (final c in _byDate(contributions))
    BuyTiming(
      c.contributedOn,
      c.contributedOn
          .difference(
            DateTime(
              c.contributedOn.year,
              c.contributedOn.month,
              settings.buyDay,
            ),
          )
          .inDays,
    ),
];

/// Month-end price changes, and the change over the previous 12 months.
class MonthlyReturn {
  const MonthlyReturn({
    required this.month,
    required this.monthly,
    this.rolling12,
  });

  final String month;

  /// Fraction, 0.05 = +5%.
  final double monthly;
  final double? rolling12;
}

/// Price change from one month-end to the next, plus the 12-month change once
/// there are 12 earlier months. Needs at least two month-ends.
List<MonthlyReturn> monthlyReturns(List<PricePoint> points) {
  final lastOfMonth = <String, double>{};
  for (final p in points) {
    lastOfMonth[monthKey(p.date)] = p.price;
  }
  final months = lastOfMonth.keys.toList()..sort();
  final out = <MonthlyReturn>[];
  for (var i = 1; i < months.length; i++) {
    final price = lastOfMonth[months[i]]!;
    final prev = lastOfMonth[months[i - 1]]!;
    double? rolling;
    if (i >= 12) rolling = price / lastOfMonth[months[i - 12]]! - 1;
    out.add(
      MonthlyReturn(
        month: months[i],
        monthly: price / prev - 1,
        rolling12: rolling,
      ),
    );
  }
  return out;
}

/// Counts of [values] in bins of [width] starting at a multiple of [width].
class HistogramBin {
  const HistogramBin(this.from, this.count);

  final double from;
  final int count;
}

List<HistogramBin> histogram(List<double> values, double width) {
  if (values.isEmpty) return const [];
  final lo = (values.reduce((a, b) => a < b ? a : b) / width).floor();
  final hi = (values.reduce((a, b) => a > b ? a : b) / width).floor();
  final counts = List<int>.filled(hi - lo + 1, 0);
  for (final v in values) {
    counts[(v / width).floor() - lo]++;
  }
  return [
    for (var i = 0; i < counts.length; i++)
      HistogramBin((lo + i) * width, counts[i]),
  ];
}

/// Journal entries per month and type.
Map<String, Map<JournalEntryType, int>> journalActivity(
  List<JournalEntryModel> entries,
  List<String> months,
) {
  final out = {
    for (final m in months) m: {for (final t in JournalEntryType.values) t: 0},
  };
  for (final e in entries) {
    final bucket = out[monthKey(e.createdAt)];
    if (bucket != null) bucket[e.entryType] = bucket[e.entryType]! + 1;
  }
  return out;
}

/// Rule findings per month and check (WAIT_PERIOD, PLAN_CHANGE, MISSED_MONTH).
class RuleMonths {
  const RuleMonths(this.byMonth, this.checks);

  final Map<String, Map<String, int>> byMonth;

  /// The checks that appear at least once, in a stable order.
  final List<String> checks;

  int total(String month) =>
      (byMonth[month] ?? const <String, int>{}).values.fold(0, (a, b) => a + b);

  /// Months with no finding at all.
  int cleanMonths() => byMonth.keys.where((m) => total(m) == 0).length;
}

RuleMonths ruleFindingsByMonth(
  List<RuleFindingModel> findings,
  List<String> months,
) {
  final byMonth = {for (final m in months) m: <String, int>{}};
  final seen = <String>{};
  for (final f in findings) {
    final bucket = byMonth[f.date.substring(0, 7)];
    if (bucket == null) continue;
    bucket[f.check] = (bucket[f.check] ?? 0) + 1;
    seen.add(f.check);
  }
  return RuleMonths(byMonth, seen.toList()..sort());
}

/// Cards coming due, day by day. Day 0 holds today's and anything overdue.
class CardsDue {
  const CardsDue({
    required this.perDay,
    required this.later,
    required this.lapsedCards,
    required this.reviewedCards,
  });

  final List<int> perDay;

  /// Due after the last day shown.
  final int later;

  /// Cards that have lapsed at least once.
  final int lapsedCards;

  /// Cards that have been reviewed at least once.
  final int reviewedCards;
}

CardsDue cardsDue(List<FlashcardModel> cards, DateTime today, {int days = 14}) {
  final start = DateTime(today.year, today.month, today.day);
  final perDay = List<int>.filled(days, 0);
  var later = 0, lapsed = 0, reviewed = 0;
  for (final c in cards) {
    final due = DateTime(c.dueOn.year, c.dueOn.month, c.dueOn.day);
    final offset = due.difference(start).inDays;
    if (offset >= days) {
      later++;
    } else {
      perDay[offset < 0 ? 0 : offset]++;
    }
    if (c.lapses > 0) lapsed++;
    if (c.repetitions > 0 || c.lapses > 0) reviewed++;
  }
  return CardsDue(
    perDay: perDay,
    later: later,
    lapsedCards: lapsed,
    reviewedCards: reviewed,
  );
}

/// Reading list by status.
Map<SourceStatus, int> readingProgress(List<LearningSourceModel> sources) => {
  for (final s in SourceStatus.values)
    s: sources.where((x) => x.status == s).length,
};

/// Reminders sent in a month, by kind.
class MonthReminders {
  const MonthReminders({required this.due, required this.followup});

  final int due;
  final int followup;
}

Map<String, MonthReminders> remindersByMonth(
  List<SentReminder> sent,
  List<String> months,
) {
  final due = {for (final m in months) m: 0};
  final follow = {for (final m in months) m: 0};
  for (final r in sent) {
    if (!due.containsKey(r.month)) continue;
    if (r.kind == 'FOLLOWUP') {
      follow[r.month] = follow[r.month]! + 1;
    } else {
      due[r.month] = due[r.month]! + 1;
    }
  }
  return {
    for (final m in months)
      m: MonthReminders(due: due[m]!, followup: follow[m]!),
  };
}

/// A plan change placed on the timeline, with a short label.
class PlanChangeMark {
  const PlanChangeMark(this.date, this.label);

  final DateTime date;
  final String label;
}

List<PlanChangeMark> planChangeMarks(
  List<SettingsChangeModel> changes,
  String Function(int cents) money,
) => [
  for (final c in changes)
    PlanChangeMark(c.changedAt, switch (c.field) {
      'MONTHLY_AMOUNT' =>
        'Amount ${_cents(c.oldValue, money)} to ${_cents(c.newValue, money)}',
      'TICKER' => 'Fund ${c.oldValue} to ${c.newValue}',
      'BUY_DAY' => 'Buy day ${c.oldValue} to ${c.newValue}',
      _ => '${c.field}: ${c.oldValue} to ${c.newValue}',
    }),
];

String _cents(String raw, String Function(int cents) money) {
  final v = int.tryParse(raw);
  return v == null ? raw : money(v);
}
