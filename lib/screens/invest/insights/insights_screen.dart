import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/invest/contribution_model.dart';
import '../../../models/invest/contribution_status_model.dart';
import '../../../models/invest/insights_model.dart';
import '../../../models/invest/invest_settings_model.dart';
import '../../../models/invest/journal_model.dart';
import '../../../models/invest/learning_model.dart';
import '../../../models/invest/performance_model.dart';
import '../../../models/invest/plan_model.dart';
import '../../../models/invest/rule_check_model.dart';
import '../../../services/ai_chat_service.dart';
import '../../../services/contribution_service.dart';
import '../../../services/journal_service.dart';
import '../../../services/learning_service.dart';
import '../../../services/plan_service.dart';
import '../value_chart_card.dart';
import 'insights_charts.dart';
import 'insights_data.dart';
import 'insights_kit.dart';

Future<(A, B)> _both<A, B>(Future<A> a, Future<B> b) async {
  final ra = await a;
  return (ra, await b);
}

/// Every chart about the plan, in one scrolling page. Each chart loads its own
/// data, so a source that fails leaves a quiet note and the rest still draw.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({
    super.key,
    ContributionService? contributions,
    PlanService? plan,
    JournalService? journal,
    LearningService? learning,
    AiChatService? ai,
    this.now,
  }) : _contributions = contributions,
       _plan = plan,
       _journal = journal,
       _learning = learning,
       _ai = ai;

  final ContributionService? _contributions;
  final PlanService? _plan;
  final JournalService? _journal;
  final LearningService? _learning;
  final AiChatService? _ai;

  /// For tests; defaults to the current time.
  final DateTime Function()? now;

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  ContributionService get _contributions =>
      widget._contributions ?? ContributionService.shared;
  PlanService get _plan => widget._plan ?? PlanService.shared;
  JournalService get _journal => widget._journal ?? JournalService.shared;
  LearningService get _learning => widget._learning ?? LearningService.shared;
  AiChatService get _ai => widget._ai ?? AiChatService.shared;

  late final DateTime _now = (widget.now ?? DateTime.now)();
  late final List<String> _months = lastMonths(_now, 12);

  late final Future<InvestSettingsModel> _settings;
  late final Future<PerformanceModel> _performance;
  late final Future<List<ContributionModel>> _buys;
  late final Future<ContributionStatusModel> _status;
  late final Future<List<SettingsChangeModel>> _changes;
  late final Future<List<JournalEntryModel>> _entries;
  late final Future<RuleCheckModel> _rules;
  late final Future<List<FlashcardModel>> _cards;
  late final Future<List<LearningSourceModel>> _sources;
  late final Future<ReminderStatusModel> _reminders;
  late final Future<AiUsageHistoryModel> _aiHistory;

  @override
  void initState() {
    super.initState();
    // Started together so the page fills in at once. A chart far down the page
    // may not be on screen yet when its data fails, so each error is marked as
    // handled here; the chart still shows it when it is built.
    _settings = _contributions.getSettings()..ignore();
    _performance = _contributions.getPerformance()..ignore();
    _buys = _contributions.getAll()..ignore();
    _status = _contributions.getStatus()..ignore();
    _changes = _plan.settingsChanges()..ignore();
    _entries = _loadJournal()..ignore();
    _rules = _plan.ruleCheck(from: monthStart(_months.first), to: _now)
      ..ignore();
    _cards = _learning.cards()..ignore();
    _sources = _learning.sources()..ignore();
    _reminders = _plan.reminderStatus()..ignore();
    _aiHistory = _ai.usageHistory()..ignore();
  }

  Future<List<JournalEntryModel>> _loadJournal() async {
    final out = <JournalEntryModel>[];
    for (var page = 0; page < 10; page++) {
      final p = await _journal.list(
        from: monthStart(_months.first),
        page: page,
        size: 100,
      );
      out.addAll(p.items);
      if (!p.hasMore) break;
    }
    return out;
  }

  NumberFormat _money(String currency) =>
      NumberFormat.simpleCurrency(name: currency);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Charts', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Everything about your plan in pictures, from what you have already recorded.',
              style: theme.textTheme.bodyMedium,
            ),
            _heading('Your plan'),
            _valueChart(),
            _contributionsByMonth(),
            _costBasis(),
            _allocation(),
            _planGrid(),
            _heading('How you buy'),
            _fundPicker(),
            _fees(),
            _sharesOwned(),
            _buysOnPrice(),
            _plannedVsActual(),
            _timing(),
            _planChanges(),
            _heading('How the price moved'),
            _monthlyReturns(),
            _rolling12(),
            _heading('Habits'),
            _journalActivity(),
            _ruleFindings(),
            _reminderTimeline(),
            _heading('Learning and AI'),
            _flashcards(),
            _reading(),
            _aiUsage(),
          ].expand((w) => [w, if (w is! Padding) const SizedBox(height: 12)]).toList(),
        ),
      ),
    );
  }

  /// The fund the per-fund charts show; the first one until a chip is tapped.
  final ValueNotifier<int?> _fund = ValueNotifier(null);

  @override
  void dispose() {
    _fund.dispose();
    super.dispose();
  }

  /// Builds a per-fund chart for the chosen fund. With one fund it is the
  /// whole portfolio, as before.
  Widget _scoped(
    PerformanceModel performance,
    List<ContributionModel> buys,
    Widget Function(FundScope scope) build,
  ) => ValueListenableBuilder<int?>(
    valueListenable: _fund,
    builder: (context, id, _) => build(fundScope(performance, buys, id)),
  );

  /// "VT: " in front of a note when a single fund of several is shown.
  String _of(FundScope scope, String note) =>
      scope.ticker == null ? note : '${scope.ticker}. $note';

  Widget _fundPicker() => InsightLoader<PerformanceModel>(
    load: () => _performance,
    title: 'Fund',
    builder: (context, performance) {
      if (!performance.isMixed) return const SizedBox.shrink();
      return ValueListenableBuilder<int?>(
        valueListenable: _fund,
        builder: (context, id, _) {
          final selected = fundScope(performance, const [], id).ticker;
          return InsightCard(
            title: 'Fund',
            note: 'The charts below are drawn for one fund at a time.',
            height: null,
            child: Wrap(
              spacing: 8,
              children: [
                for (final h in performance.holdings)
                  ChoiceChip(
                    key: Key('fund-chip-${h.holdingId}'),
                    label: Text(h.ticker),
                    selected: h.ticker == selected,
                    onSelected: (_) => _fund.value = h.holdingId,
                  ),
              ],
            ),
          );
        },
      );
    },
  );

  Widget _allocation() => InsightLoader<PerformanceModel>(
    load: () => _performance,
    title: 'Allocation against target',
    builder: (context, performance) {
      if (!performance.isMixed) return const SizedBox.shrink();
      final c = ChartColors.of(context);
      final off = performance.holdings
          .where((h) => (h.driftPoints ?? 0).abs() > 5)
          .map((h) => h.ticker)
          .toList();
      return InsightCard(
        title: 'Allocation against target',
        note:
            'Each fund\'s share of the portfolio now, next to the share you aim for.',
        summary: off.isEmpty
            ? 'Every fund is within 5 points of its target.'
            : 'More than 5 points from target: ${off.join(', ')}.',
        legend: [
          LegendItem('Share now', c.accent),
          LegendItem('Target', c.second, outlined: true),
        ],
        child: AllocationChart(funds: performance.holdings),
      );
    },
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 0),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );

  // ------------------------------------------------------------ your plan

  Widget _valueChart() => InsightLoader<PerformanceModel>(
    load: () => _performance,
    title: 'Invested vs value',
    builder: (context, performance) => ValueChartCard(
      initial: performance,
      loader: (range) => _contributions.getPerformance(range: range),
    ),
  );

  Widget _contributionsByMonth() =>
      InsightLoader<(ContributionStatusModel, InvestSettingsModel)>(
        load: () => _both(_status, _settings),
        title: 'Contributions by month',
        builder: (context, data) {
          final (status, settings) = data;
          final months = plannedVsActual(status, settings);
          final done = months.where((m) => m.state == MonthState.done).length;
          final c = ChartColors.of(context);
          return InsightCard(
            title: 'Contributions by month',
            note: 'An outlined bar is a planned month with no buy.',
            summary: months.isEmpty
                ? null
                : '$done of ${months.length} planned months bought. Longest run: ${status.longestStreak}.',
            legend: [
              LegendItem('Bought', c.accent),
              LegendItem('Planned, not bought', c.bad, outlined: true),
            ],
            child: ContributionsByMonthChart(
              months: months,
              currency: settings.currency,
            ),
          );
        },
      );

  Widget
  _costBasis() => InsightLoader<(PerformanceModel, List<ContributionModel>)>(
    load: () => _both(_performance, _buys),
    title: 'Average cost against price',
    builder: (context, data) {
      final (performance, allBuys) = data;
      return _scoped(performance, allBuys, (scope) {
        final buys = scope.buys;
        final points = pricePoints(scope.series, buys);
        final c = ChartColors.of(context);
        final money = _money(performance.currency);
        String? summary;
        if (points.isNotEmpty) {
          final last = points.last;
          final diff = last.price / last.avgCost - 1;
          summary =
              'Price ${money.format(last.price)} against an average cost of ${money.format(last.avgCost)}: '
              '${diff >= 0 ? 'ahead' : 'behind'} by ${NumberFormat.decimalPercentPattern(decimalDigits: 1).format(diff.abs())}.';
        }
        return InsightCard(
          title: 'Average cost against price',
          note: _of(
            scope,
            'When the price line is above the dashed line, the position is in profit.',
          ),
          summary: summary,
          legend: [
            LegendItem('Price per share', c.muted),
            LegendItem('Your average cost', c.accent, dashed: true),
          ],
          child: PriceLineChart(
            points: points,
            currency: performance.currency,
            showAvgCost: true,
          ),
        );
      });
    },
  );

  Widget _planGrid() => InsightLoader<ContributionStatusModel>(
    load: () => _status,
    title: 'Did the plan happen?',
    builder: (context, status) {
      final c = ChartColors.of(context);
      return InsightCard(
        title: 'Did the plan happen?',
        note: 'One cell per month since the plan started.',
        summary:
            'Current run: ${status.currentStreak} months. Missed so far: ${status.missedCount}.',
        legend: [
          LegendItem('Bought', c.accent),
          LegendItem('Missed', c.bad),
          LegendItem('Due, not bought yet', c.bad, outlined: true),
          LegendItem('Not due yet', c.muted, outlined: true),
        ],
        height: null,
        child: MonthGrid(
          cells: planCells(status, c, NumberFormat.simpleCurrency()),
        ),
      );
    },
  );

  // ----------------------------------------------------------- how you buy

  Widget
  _fees() => InsightLoader<(List<ContributionModel>, InvestSettingsModel)>(
    load: () => _both(_buys, _settings),
    title: 'Fees paid',
    builder: (context, data) {
      final (buys, settings) = data;
      final fees = feesRunning(buys);
      final money = _money(settings.currency);
      final total = fees.isEmpty ? 0.0 : fees.last.value;
      final withFee = buys.where((b) => b.feeCents > 0).length;
      return InsightCard(
        title: 'Fees paid',
        note:
            'Running total of what you paid in fees, stepping up at each buy.',
        summary:
            '${money.format(total)} in fees across $withFee of ${buys.length} buys.',
        child: StepTotalChart(
          values: fees,
          axisFormat: money.format,
          tooltipFormat: (v) => '${money.format(v)} in fees so far',
          color: ChartColors.of(context).second,
        ),
      );
    },
  );

  Widget
  _sharesOwned() => InsightLoader<(PerformanceModel, List<ContributionModel>)>(
    load: () => _both(_performance, _buys),
    title: 'Shares owned',
    builder: (context, data) {
      final (performance, allBuys) = data;
      return _scoped(performance, allBuys, (scope) {
        final buys = scope.buys;
        final shares = sharesOwned(buys);
        return InsightCard(
          title: 'Shares owned',
          note: _of(scope, 'Grows with every buy, whatever the price did.'),
          summary: shares.isEmpty
              ? null
              : '${shares.last.value.toStringAsFixed(2)} shares after ${buys.length} buys.',
          child: StepTotalChart(
            values: shares,
            axisFormat: (v) => v.toStringAsFixed(0),
            tooltipFormat: (v) => '${v.toStringAsFixed(2)} shares',
            color: ChartColors.of(context).accent,
          ),
        );
      });
    },
  );

  Widget
  _buysOnPrice() => InsightLoader<(PerformanceModel, List<ContributionModel>)>(
    load: () => _both(_performance, _buys),
    title: 'Each buy on the price line',
    builder: (context, data) {
      final (performance, allBuys) = data;
      return _scoped(performance, allBuys, (scope) {
        final buys = scope.buys;
        final points = pricePoints(scope.series, buys);
        final c = ChartColors.of(context);
        final money = _money(performance.currency);
        var avg = 0.0;
        if (buys.isNotEmpty) {
          avg = buys.fold<double>(0, (a, b) => a + b.price) / buys.length;
        }
        return InsightCard(
          title: 'Each buy on the price line',
          note: _of(
            scope,
            'Shows whether you bought high or low, without trying to time it.',
          ),
          summary: buys.isEmpty
              ? null
              : 'Average buy price ${money.format(avg)}${points.isEmpty ? '' : ', latest price ${money.format(points.last.price)}'}.',
          legend: [
            LegendItem('Price per share', c.accent),
            LegendItem('A buy', c.second, dot: true),
          ],
          child: PriceLineChart(
            points: points,
            currency: performance.currency,
            buys: [
              for (final b in buys) (date: b.contributedOn, price: b.price),
            ],
          ),
        );
      });
    },
  );

  Widget
  _plannedVsActual() => InsightLoader<(ContributionStatusModel, InvestSettingsModel)>(
    load: () => _both(_status, _settings),
    title: 'Planned against actual',
    builder: (context, data) {
      final (status, settings) = data;
      final months = plannedVsActual(status, settings);
      final c = ChartColors.of(context);
      final money = _money(settings.currency);
      final onPlan = months.where((m) => m.differenceCents == 0).length;
      final diff = months.fold<int>(0, (a, m) => a + m.differenceCents) / 100;
      return InsightCard(
        title: 'Planned against actual',
        note:
            'Above zero: you put in more than planned that month. Below: less.',
        summary: months.isEmpty
            ? null
            : 'Exactly on plan in $onPlan of ${months.length} months. In total ${money.format(diff.abs())} ${diff >= 0 ? 'more' : 'less'} than planned.',
        legend: [
          LegendItem('More than planned', c.accent),
          LegendItem('Less than planned', c.bad),
        ],
        child: PlannedVsActualChart(
          months: months,
          currency: settings.currency,
        ),
      );
    },
  );

  Widget
  _timing() => InsightLoader<(List<ContributionModel>, InvestSettingsModel)>(
    load: () => _both(_buys, _settings),
    title: 'Buy timing',
    builder: (context, data) {
      final (buys, settings) = data;
      final timing = buyTiming(buys, settings);
      final c = ChartColors.of(context);
      final avg = timing.isEmpty
          ? 0.0
          : timing.fold<int>(0, (a, t) => a + t.daysAfter) / timing.length;
      final late = timing.where((t) => t.daysAfter > 0).length;
      return InsightCard(
        title: 'Buy timing',
        note:
            'Days after the planned buy day (day ${settings.buyDay}) that each buy happened.',
        summary: timing.isEmpty
            ? null
            : 'On average ${avg.toStringAsFixed(1)} days after the planned day. $late of ${timing.length} buys came late.',
        legend: [LegendItem('Late', c.second), LegendItem('Early', c.accent)],
        child: BuyTimingChart(timing: timing),
      );
    },
  );

  Widget
  _planChanges() => InsightLoader<(PerformanceModel, List<SettingsChangeModel>)>(
    load: () => _both(_performance, _changes),
    title: 'Plan changes on the value chart',
    builder: (context, data) {
      final (performance, changes) = data;
      final money = _money(performance.currency);
      final marks = planChangeMarks(
        changes,
        (cents) => money.format(cents / 100),
      );
      final c = ChartColors.of(context);
      final df = DateFormat.yMMMd();
      return InsightCard(
        title: 'Plan changes on the value chart',
        note:
            'A dashed line marks the day the amount, fund or buy day changed.',
        summary: marks.isEmpty
            ? 'No plan changes recorded yet.'
            : marks.map((m) => '${df.format(m.date)}: ${m.label}').join('\n'),
        legend: [
          LegendItem('Value', c.accent),
          LegendItem('Plan changed', c.second, dashed: true),
        ],
        child: ValueWithChangesChart(
          series: performance.series,
          marks: marks,
          currency: performance.currency,
        ),
      );
    },
  );

  // ----------------------------------------------------- how the price moved

  Widget
  _monthlyReturns() => InsightLoader<(PerformanceModel, List<ContributionModel>)>(
    load: () => _both(_performance, _buys),
    title: 'Best and worst months',
    builder: (context, data) {
      final (performance, allBuys) = data;
      return _scoped(performance, allBuys, (scope) {
        final returns = monthlyReturns(pricePoints(scope.series, scope.buys));
        final c = ChartColors.of(context);
        final pct = NumberFormat('+0.0%;−0.0%');
        String? summary;
        if (returns.isNotEmpty) {
          final best = returns.reduce((a, b) => a.monthly >= b.monthly ? a : b);
          final worst = returns.reduce(
            (a, b) => a.monthly <= b.monthly ? a : b,
          );
          final up = returns.where((r) => r.monthly > 0).length;
          summary =
              'Best month ${pct.format(best.monthly)} (${DateFormat.yMMM().format(monthStart(best.month))}), '
              'worst ${pct.format(worst.monthly)} (${DateFormat.yMMM().format(monthStart(worst.month))}). '
              'Up in $up of ${returns.length} months.';
        }
        return InsightCard(
          title: 'Best and worst months',
          note: _of(
            scope,
            'How many months fell in each band of price change. Most months are ordinary; a few are not.',
          ),
          summary: summary,
          legend: [
            LegendItem('Month fell', c.bad),
            LegendItem('Month rose', c.accent),
          ],
          child: ReturnsHistogram(returns: returns),
        );
      });
    },
  );

  Widget
  _rolling12() => InsightLoader<(PerformanceModel, List<ContributionModel>)>(
    load: () => _both(_performance, _buys),
    title: 'Rolling 12-month change',
    builder: (context, data) {
      final (performance, allBuys) = data;
      return _scoped(performance, allBuys, (scope) {
        final returns = monthlyReturns(pricePoints(scope.series, scope.buys));
        final withYear = returns.where((r) => r.rolling12 != null).toList();
        final pct = NumberFormat('+0.0%;−0.0%');
        return InsightCard(
          title: 'Rolling 12-month change',
          note: _of(
            scope,
            'The price change over the year before each month-end.',
          ),
          summary: withYear.isEmpty
              ? null
              : 'Latest: ${pct.format(withYear.last.rolling12)} over the last 12 months.',
          child: Rolling12Chart(returns: returns),
        );
      });
    },
  );

  // ----------------------------------------------------------------- habits

  Widget _journalActivity() => InsightLoader<List<JournalEntryModel>>(
    load: () => _entries,
    title: 'Journal activity',
    builder: (context, entries) {
      final c = ChartColors.of(context);
      final activity = journalActivity(entries, _months);
      final colors = {
        JournalEntryType.checkin: c.accent,
        JournalEntryType.quick: c.second,
        JournalEntryType.decision: c.third,
      };
      final total = entries.length;
      return InsightCard(
        title: 'Journal activity',
        note: 'Entries per month for the last 12 months.',
        summary:
            '$total entries: ${[for (final t in JournalEntryType.values) '${entries.where((e) => e.entryType == t).length} ${t.label.toLowerCase()}'].join(', ')}.',
        legend: [
          for (final t in JournalEntryType.values)
            LegendItem(t.label, colors[t]!),
        ],
        child: StackedMonthChart(
          months: _months,
          series: [
            for (final t in JournalEntryType.values)
              StackSeries(t.label, colors[t]!, [
                for (final m in _months) activity[m]![t]!,
              ]),
          ],
        ),
      );
    },
  );

  Widget _ruleFindings() => InsightLoader<RuleCheckModel>(
    load: () => _rules,
    title: 'Rules and deviations',
    builder: (context, result) {
      final c = ChartColors.of(context);
      final grouped = ruleFindingsByMonth(result.findings, _months);
      const labels = {
        'WAIT_PERIOD': 'Acted before the wait',
        'PLAN_CHANGE': 'Plan changed',
        'MISSED_MONTH': 'Missed month',
      };
      final palette = [c.second, c.third, c.bad, c.accent];
      final kinds = grouped.checks;
      final totalFindings = _months.fold<int>(
        0,
        (a, m) => a + grouped.total(m),
      );
      return InsightCard(
        title: 'Rules and deviations',
        note:
            'Things worth a second look against your own rules. Prompts to check, never verdicts.',
        summary:
            '$totalFindings ${totalFindings == 1 ? 'finding' : 'findings'} in 12 months; '
            '${grouped.cleanMonths()} of ${_months.length} months had none.',
        legend: [
          for (var i = 0; i < kinds.length; i++)
            LegendItem(
              labels[kinds[i]] ?? kinds[i],
              palette[i % palette.length],
            ),
        ],
        child: StackedMonthChart(
          months: _months,
          series: [
            for (var i = 0; i < kinds.length; i++)
              StackSeries(
                labels[kinds[i]] ?? kinds[i],
                palette[i % palette.length],
                [for (final m in _months) grouped.byMonth[m]![kinds[i]] ?? 0],
              ),
          ],
        ),
      );
    },
  );

  Widget _reminderTimeline() =>
      InsightLoader<(ReminderStatusModel, ContributionStatusModel)>(
        load: () => _both(_reminders, _status),
        title: 'Reminders and buys',
        builder: (context, data) {
          final (reminders, status) = data;
          final c = ChartColors.of(context);
          final sent = remindersByMonth(reminders.recent, _months);
          final cells = reminderCells(_months, status, sent, c);
          final emails = sent.values.fold<int>(
            0,
            (a, r) => a + r.due + r.followup,
          );
          return InsightCard(
            title: 'Reminders and buys',
            note:
                'The number in each cell is how many reminder emails were sent that month.',
            summary: reminders.emailConfigured
                ? '$emails reminder emails in the last 12 months.'
                : 'Email reminders are not set up on the server.',
            legend: [
              LegendItem('Bought', c.accent),
              LegendItem('Missed', c.bad),
              LegendItem('Not yet', c.muted, outlined: true),
            ],
            height: null,
            child: MonthGrid(cells: cells),
          );
        },
      );

  // ------------------------------------------------------- learning and AI

  Widget _flashcards() => InsightLoader<List<FlashcardModel>>(
    load: () => _cards,
    title: 'Flashcards due',
    builder: (context, cards) {
      final due = cardsDue(cards, _now);
      final c = ChartColors.of(context);
      return InsightCard(
        title: 'Flashcards due',
        note: 'Cards coming up for review over the next two weeks.',
        summary:
            '${due.perDay[0]} due now or overdue, ${due.perDay.skip(1).fold<int>(0, (a, b) => a + b)} more in the next two weeks, '
            '${due.later} later. ${due.lapsedCards} of ${due.reviewedCards} reviewed cards have been forgotten at least once.',
        legend: [
          LegendItem('Due now or overdue', c.second),
          LegendItem('Coming up', c.accent),
        ],
        child: CardsDueChart(due: due, today: _now),
      );
    },
  );

  Widget _reading() => InsightLoader<List<LearningSourceModel>>(
    load: () => _sources,
    title: 'Reading list',
    builder: (context, sources) {
      final counts = readingProgress(sources);
      return InsightCard(
        title: 'Reading list',
        note: 'Books, videos and articles you plan to learn from.',
        summary: '${counts[SourceStatus.done]} of ${sources.length} finished.',
        height: null,
        child: ReadingProgressBar(counts: counts),
      );
    },
  );

  Widget _aiUsage() => InsightLoader<AiUsageHistoryModel>(
    load: () => _aiHistory,
    title: 'AI questions per day',
    builder: (context, history) {
      final today = history.days.isEmpty ? 0 : history.days.last.calls;
      final busiest = history.days.fold<int>(
        0,
        (a, d) => d.calls > a ? d.calls : a,
      );
      return InsightCard(
        title: 'AI questions per day',
        note:
            'Model calls over the last 30 days against the daily limit set on the server.',
        summary:
            '$today of ${history.dailyLimit} used today. Busiest day: $busiest.',
        child: AiUsageChart(history: history),
      );
    },
  );
}
