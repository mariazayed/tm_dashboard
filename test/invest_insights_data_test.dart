import 'package:flutter_test/flutter_test.dart';
import 'package:tm_dashboard/models/invest/contribution_model.dart';
import 'package:tm_dashboard/models/invest/contribution_status_model.dart';
import 'package:tm_dashboard/models/invest/insights_model.dart';
import 'package:tm_dashboard/models/invest/invest_settings_model.dart';
import 'package:tm_dashboard/models/invest/journal_model.dart';
import 'package:tm_dashboard/models/invest/learning_model.dart';
import 'package:tm_dashboard/models/invest/performance_model.dart';
import 'package:tm_dashboard/models/invest/plan_model.dart';
import 'package:tm_dashboard/models/invest/rule_check_model.dart';
import 'package:tm_dashboard/screens/invest/insights/insights_data.dart';

ContributionModel buy(
  String date, {
  int cents = 30000,
  double shares = 3,
  double price = 100,
  int fee = 0,
}) => ContributionModel(
  id: date.hashCode,
  contributedOn: DateTime.parse(date),
  amountCents: cents,
  shares: shares,
  price: price,
  feeCents: fee,
);

SeriesPoint pt(String date, int invested, int value) => SeriesPoint(
  date: DateTime.parse(date),
  investedCents: invested,
  valueCents: value,
);

final settings = InvestSettingsModel(
  monthlyAmountCents: 30000,
  currency: 'USD',
  buyDay: 5,
  ticker: 'VT',
  startDate: DateTime(2026, 1, 1),
);

void main() {
  test('lastMonths ends with the current month and crosses the year', () {
    expect(lastMonths(DateTime(2026, 2, 10), 4), [
      '2025-11',
      '2025-12',
      '2026-01',
      '2026-02',
    ]);
  });

  group('pricePoints', () {
    test('divides value and cost by the shares held that day', () {
      final points = pricePoints(
        [
          pt('2026-01-02', 0, 0), // before the first buy: skipped
          pt('2026-01-10', 30000, 31500),
          pt('2026-02-10', 60000, 66000),
        ],
        [buy('2026-01-05', shares: 3), buy('2026-02-05', shares: 2.5)],
      );
      expect(points.length, 2);
      expect(points[0].shares, 3);
      expect(points[0].price, closeTo(105, 1e-9)); // 315 / 3
      expect(points[0].avgCost, closeTo(100, 1e-9)); // 300 / 3
      expect(points[1].shares, 5.5);
      expect(points[1].price, closeTo(120, 1e-9)); // 660 / 5.5
      expect(points[1].avgCost, closeTo(600 / 5.5, 1e-9));
    });

    test('a buy on the same day counts', () {
      final points = pricePoints(
        [pt('2026-01-05', 30000, 30000)],
        [buy('2026-01-05')],
      );
      expect(points.single.shares, 3);
    });

    test('no buys means no points', () {
      expect(pricePoints([pt('2026-01-05', 0, 0)], const []), isEmpty);
    });
  });

  test('feesRunning and sharesOwned accumulate in date order', () {
    final list = [
      buy('2026-02-05', fee: 150, shares: 2),
      buy('2026-01-05', fee: 100, shares: 3),
    ];
    expect(feesRunning(list).map((e) => e.value), [1.0, 2.5]);
    expect(sharesOwned(list).map((e) => e.value), [3.0, 5.0]);
    expect(feesRunning(list).first.date, DateTime(2026, 1, 5));
  });

  test('plannedVsActual skips the month still waiting for its buy day', () {
    const status = ContributionStatusModel(
      months: [
        MonthStatus(
          month: '2026-01',
          state: MonthState.done,
          contributions: 1,
          totalCents: 45000,
        ),
        MonthStatus(
          month: '2026-02',
          state: MonthState.missed,
          contributions: 0,
          totalCents: 0,
        ),
        MonthStatus(
          month: '2026-03',
          state: MonthState.pending,
          contributions: 0,
          totalCents: 0,
        ),
      ],
      currentStreak: 0,
      longestStreak: 1,
      missedCount: 1,
    );
    final plan = plannedVsActual(status, settings);
    expect(plan.map((m) => m.month), ['2026-01', '2026-02']);
    expect(plan[0].differenceCents, 15000);
    expect(plan[1].differenceCents, -30000);
  });

  test('buyTiming counts days from the planned day, early or late', () {
    final t = buyTiming([
      buy('2026-01-05'),
      buy('2026-02-09'),
      buy('2026-03-03'),
    ], settings);
    expect(t.map((e) => e.daysAfter), [0, 4, -2]);
  });

  group('monthlyReturns', () {
    PricePoint p(String date, double price) => PricePoint(
      date: DateTime.parse(date),
      shares: 1,
      price: price,
      avgCost: 100,
    );

    test('uses the last price of each month', () {
      final r = monthlyReturns([
        p('2026-01-10', 90),
        p('2026-01-31', 100),
        p('2026-02-15', 120),
        p('2026-02-28', 110),
      ]);
      expect(r.length, 1);
      expect(r.single.month, '2026-02');
      expect(r.single.monthly, closeTo(0.10, 1e-9));
      expect(r.single.rolling12, isNull);
    });

    test('rolling 12 appears once a year of history exists', () {
      final points = [
        for (var i = 0; i < 14; i++)
          p(
            '${2025 + (i ~/ 12)}-${(i % 12 + 1).toString().padLeft(2, '0')}-28',
            100.0 + i,
          ),
      ];
      final r = monthlyReturns(points);
      expect(r.length, 13);
      expect(r[10].rolling12, isNull);
      expect(
        r[11].rolling12,
        closeTo(112 / 100 - 1, 1e-9),
      ); // Jan 2026 against Jan 2025
    });

    test('fewer than two months gives nothing', () {
      expect(monthlyReturns([p('2026-01-10', 90)]), isEmpty);
    });
  });

  test('histogram bins by width and keeps empty bins between', () {
    final h = histogram([-0.031, 0.002, 0.009, 0.051], 0.02);
    expect(h.first.from, closeTo(-0.04, 1e-9));
    expect(h.map((b) => b.count).reduce((a, b) => a + b), 4);
    expect(h.length, 5); // -0.04, -0.02, 0, 0.02, 0.04
    expect(h[2].count, 2);
    expect(histogram(const [], 0.02), isEmpty);
  });

  test('journalActivity counts by month and type and ignores other months', () {
    JournalEntryModel e(String at, JournalEntryType t) => JournalEntryModel(
      id: at.hashCode,
      entryType: t,
      body: '',
      tags: const [],
      createdAt: DateTime.parse(at),
    );
    final a = journalActivity(
      [
        e('2026-01-03T10:00:00', JournalEntryType.checkin),
        e('2026-01-20T10:00:00', JournalEntryType.quick),
        e('2026-01-21T10:00:00', JournalEntryType.quick),
        e('2025-06-01T10:00:00', JournalEntryType.decision),
      ],
      ['2026-01', '2026-02'],
    );
    expect(a['2026-01']![JournalEntryType.quick], 2);
    expect(a['2026-01']![JournalEntryType.checkin], 1);
    expect(a['2026-02']!.values.every((v) => v == 0), isTrue);
  });

  test('ruleFindingsByMonth groups by check and counts clean months', () {
    RuleFindingModel f(String date, String check) =>
        RuleFindingModel(check: check, date: date, message: 'm');
    final r = ruleFindingsByMonth(
      [
        f('2026-01-04', 'WAIT_PERIOD'),
        f('2026-01-09', 'WAIT_PERIOD'),
        f('2026-02-01', 'MISSED_MONTH'),
        f('2025-01-01', 'PLAN_CHANGE'), // outside the months asked about
      ],
      ['2026-01', '2026-02', '2026-03'],
    );
    expect(r.byMonth['2026-01']!['WAIT_PERIOD'], 2);
    expect(r.total('2026-02'), 1);
    expect(r.cleanMonths(), 1);
    expect(r.checks, ['MISSED_MONTH', 'WAIT_PERIOD']);
  });

  test(
    'cardsDue lumps overdue into day 0 and counts later cards separately',
    () {
      FlashcardModel c(String due, {int reps = 0, int lapses = 0}) =>
          FlashcardModel(
            id: due.hashCode,
            front: 'f',
            back: 'b',
            dueOn: DateTime.parse(due),
            intervalDays: 1,
            repetitions: reps,
            lapses: lapses,
          );
      final d = cardsDue([
        c('2026-09-30'), // overdue
        c('2026-10-15'), // today
        c('2026-10-17', reps: 2),
        c('2026-10-28', lapses: 1), // day 13: last day shown
        c('2026-10-29'), // day 14: later
      ], DateTime(2026, 10, 15, 14, 30));
      expect(d.perDay[0], 2);
      expect(d.perDay[2], 1);
      expect(d.perDay[13], 1);
      expect(d.later, 1);
      expect(d.lapsedCards, 1);
      expect(d.reviewedCards, 2);
    },
  );

  test('readingProgress counts every status, including empty ones', () {
    LearningSourceModel s(SourceStatus st) => LearningSourceModel(
      id: st.index,
      title: 't',
      sourceType: SourceType.book,
      status: st,
    );
    final p = readingProgress([
      s(SourceStatus.done),
      s(SourceStatus.done),
      s(SourceStatus.todo),
    ]);
    expect(p[SourceStatus.done], 2);
    expect(p[SourceStatus.todo], 1);
    expect(p[SourceStatus.inProgress], 0);
  });

  test('remindersByMonth separates due reminders from follow-ups', () {
    final r = remindersByMonth(
      [
        SentReminder(
          month: '2026-01',
          kind: 'DUE',
          sentAt: DateTime(2026, 1, 5),
        ),
        SentReminder(
          month: '2026-01',
          kind: 'FOLLOWUP',
          sentAt: DateTime(2026, 1, 8),
        ),
        SentReminder(
          month: '2025-01',
          kind: 'DUE',
          sentAt: DateTime(2025, 1, 5),
        ),
      ],
      ['2026-01', '2026-02'],
    );
    expect(r['2026-01']!.due, 1);
    expect(r['2026-01']!.followup, 1);
    expect(r['2026-02']!.due, 0);
  });

  test('planChangeMarks writes a readable label for each field', () {
    String money(int c) => '\$${c ~/ 100}';
    final marks = planChangeMarks([
      SettingsChangeModel(
        field: 'MONTHLY_AMOUNT',
        oldValue: '30000',
        newValue: '45000',
        changedAt: DateTime(2026, 4, 2),
      ),
      SettingsChangeModel(
        field: 'TICKER',
        oldValue: 'VT',
        newValue: 'VTI',
        changedAt: DateTime(2026, 5, 2),
      ),
      SettingsChangeModel(
        field: 'BUY_DAY',
        oldValue: '1',
        newValue: '5',
        changedAt: DateTime(2026, 6, 2),
      ),
    ], money);
    expect(marks.map((m) => m.label), [
      'Amount \$300 to \$450',
      'Fund VT to VTI',
      'Buy day 1 to 5',
    ]);
  });
}
