import 'dart:math';

import 'package:flutter/material.dart';

import 'package:tm_dashboard/widgets/page_back_button.dart';

import '../../enums/capital_reason_enum.dart';
import '../../models/capital_model.dart';
import '../../models/expense_model.dart';
import '../../models/reminder_note_model.dart';
import '../../models/strict_rule_model.dart';
import '../../models/trade_model.dart';
import '../../services/capital_service.dart';
import '../../services/expense_service.dart';
import '../../services/reminder_notes_service.dart';
import '../../services/strict_rules_service.dart';
import '../../services/trade_service.dart';
import '../../theme/app_theme.dart';
import 'capital_growth_chart.dart';
import 'capital_list.dart';
import 'dashboard_note_strip.dart';
import 'classes/capital_dashboard_helper.dart';
import 'classes/expense_dashboard_helper.dart';
import 'classes/trade_analytics_helper.dart';
import 'expense_summary_chart.dart';
import 'goals_progress_section.dart';
import 'planner_dashboard_section.dart';
import 'session_performance_chart.dart';
import 'strategy_performance_chart.dart';
import 'summary_section.dart';
import 'trade_stats_row.dart';
import 'weekly_history_table.dart';
import 'weekly_pnl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  CapitalDashboardHelper? _helper;
  List<CapitalModel> _capitals = [];

  List<ReminderNoteModel> _notes = [];
  List<StrictRuleModel> _rules = [];
  bool _isNotesLoading = true;
  bool _isRulesLoading = true;
  int _currentNoteIndex = 0;
  int _currentRuleIndex = 0;
  final _sectionKeys = List.generate(5, (_) => GlobalKey());
  bool _showAllWeeks = false;

  // Recent-trade history backing the Trade Performance section (stat row +
  // PnL-by-strategy/session + mistake frequency). Bounded fetch -- see
  // TradeService.getRecentForAnalytics -- not the full auto-imported
  // history.
  List<Trade> _trades = [];
  TradeAnalyticsHelper? _analytics;
  bool _isTradesLoading = true;

  // Backing the Expenses summary chart. Expenses is a manually-maintained
  // standalone log (not auto-imported like Trades), so this is the same
  // full, paged-under-the-hood fetch used for the Capital ledger rather
  // than a bounded/recent one.
  List<ExpenseModel> _expenses = [];
  ExpenseDashboardHelper? _expenseHelper;
  bool _isExpensesLoading = true;

  // Accent colors for the Reminder / Strict Rule cards -- distinct from the
  // green/red PnL convention and from every categorical hue already used by
  // the charts further down this page (violet for Expenses, amber for
  // Mistake Frequency), so these two cards read as their own thing rather
  // than borrowing another section's meaning. Sourced from
  // AppSemanticColors.info/orange (see _reminderAccent/_ruleAccent getters
  // below) rather than hardcoded here, since they need to shift with
  // light/dark mode and a field initializer has no BuildContext to read
  // the theme from.
  Color _reminderAccent(BuildContext context) => context.semanticColors.info;
  Color _ruleAccent(BuildContext context) => context.semanticColors.orange;

  CapitalDashboardHelper get helper {
    final h = _helper;
    if (h != null) return h;

    final created = CapitalDashboardHelper(_capitals);

    _helper = created;
    return created;
  }

  TradeAnalyticsHelper get analytics {
    final h = _analytics;
    if (h != null) return h;

    final created = TradeAnalyticsHelper(_trades);
    _analytics = created;
    return created;
  }

  ExpenseDashboardHelper get expenseHelper {
    final h = _expenseHelper;
    if (h != null) return h;

    final created = ExpenseDashboardHelper(_expenses);
    _expenseHelper = created;
    return created;
  }

  @override
  void initState() {
    super.initState();
    _fetchCapitals();
    _fetchNotes();
    _fetchRules();
    _fetchTrades();
    _fetchExpenses();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isNotesLoading = true);

    try {
      // Paged transport under the hood instead of one unbounded GET.
      final response = await ReminderNotesService.getAllPaged();
      if (!mounted) return;
      if (response.isNotEmpty) {
        final notes = List.of(response)..shuffle(Random());

        setState(() {
          _notes = notes;
          _currentNoteIndex = 0;
          _isNotesLoading = false;
        });
      } else {
        setState(() => _isNotesLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isNotesLoading = false);
      debugPrint('Error fetching notes: $e');
    }
  }

  Future<void> _fetchRules() async {
    setState(() => _isRulesLoading = true);

    try {
      // Paged transport under the hood instead of one unbounded GET.
      final response = await StrictRulesService.getAllPaged();
      if (!mounted) return;
      if (response.isNotEmpty) {
        final rules = List.of(response)..shuffle(Random());

        setState(() {
          _rules = rules;
          _currentRuleIndex = 0;
          _isRulesLoading = false;
        });
      } else {
        setState(() => _isRulesLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRulesLoading = false);
      debugPrint('Error fetching rules: $e');
    }
  }

  Future<void> _fetchCapitals() async {
    // Paged transport under the hood instead of one unbounded GET --
    // this list grows with trade count (see CapitalService.getAllPaged).
    final capitals = await CapitalService.getAllPaged();

    if (!mounted) return;

    setState(() {
      _capitals = capitals;
      _helper = null;
    });
  }

  Future<void> _fetchTrades() async {
    try {
      // Bounded, recent-first fetch -- not the full continuously
      // auto-imported trade history. See TradeService.getRecentForAnalytics.
      final trades = await TradeService.getRecentForAnalytics();

      if (!mounted) return;

      setState(() {
        _trades = trades;
        _analytics = null;
        _isTradesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isTradesLoading = false);
      debugPrint('Error fetching trades for dashboard analytics: $e');
    }
  }

  Future<void> _fetchExpenses() async {
    try {
      // Paged transport under the hood instead of one unbounded GET -- same
      // pattern as Capital. Expenses is a manually-maintained standalone log
      // (not auto-imported like Trades), so there's no need to bound this
      // to a recent window the way TradeService.getRecentForAnalytics does.
      final expenses = await ExpenseService.fetchAllPaged();

      if (!mounted) return;

      setState(() {
        _expenses = expenses;
        _expenseHelper = null;
        _isExpensesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExpensesLoading = false);
      debugPrint('Error fetching expenses for dashboard summary: $e');
    }
  }

  void _openPnlBottomSheet({
    required String title,
    required List<CapitalModel> data,
  }) {
    final total = data.fold(0.0, (a, b) => a + b.amount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  /// Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// Total PnL
                  Text(
                    total.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: total >= 0
                          ? context.semanticColors.profit
                          : context.semanticColors.loss,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// List
                  Expanded(child: CapitalList(capitals: data)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openFilteredCapitalDialog(CapitalReasonEnum reason) {
    final filtered = _capitals.where((c) => c.reason == reason).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  /// Drag indicator
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// Title
                  Text(
                    reason == CapitalReasonEnum.DEPOSIT
                        ? "All Deposits"
                        : "All Withdraws",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// List
                  Expanded(child: CapitalList(capitals: filtered)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openPeriodDetails(String title, DateTime from) {
    final data =
        helper.capitals
            .where(
              (c) =>
                  !c.dateTime.isBefore(from) &&
                  (c.reason == CapitalReasonEnum.PROFIT ||
                      c.reason == CapitalReasonEnum.LOSS),
            )
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    _openPnlBottomSheet(title: title, data: data);
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _pair(bool wide, Widget first, Widget second) {
    if (!wide) {
      return Column(children: [first, const SizedBox(height: 20), second]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 20),
        Expanded(child: second),
      ],
    );
  }

  Widget _section(
    int index,
    String title,
    List<Widget> children, {
    String? subtitle,
  }) {
    return Padding(
      key: _sectionKeys[index],
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(context, title: title, subtitle: subtitle),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _capitalTotal(String title, double value, CapitalReasonEnum reason) {
    return TextButton.icon(
      onPressed: () => _openFilteredCapitalDialog(reason),
      icon: Icon(
        reason == CapitalReasonEnum.DEPOSIT
            ? Icons.south_west_rounded
            : Icons.north_east_rounded,
        size: 16,
      ),
      label: Text('$title  ${value.toStringAsFixed(2)}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeks = helper.weeklyBreakdown();
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: const PageBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Dashboard'),
      ),
      body: Column(
        children: [
          Material(
            color: colors.surface,
            child: SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) => TextButton(
                  onPressed: () {
                    final target = _sectionKeys[index].currentContext;
                    if (target != null) {
                      Scrollable.ensureVisible(
                        target,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  },
                  child: Text(
                    const [
                      'Overview',
                      'Capital',
                      'Trading',
                      'Planning',
                      'Expenses & History',
                    ][index],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Keep paired plots wide enough for axes and legends.
                final wide = constraints.maxWidth >= 1100;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1440),
                      child: Column(
                        children: [
                          _section(0, 'Overview', [
                            SummarySection(
                              daily: helper.summaryFrom(helper.today),
                              weekly: helper.summaryFrom(helper.weekStart),
                              monthly: helper.summaryFrom(helper.monthStart),
                              wide: constraints.maxWidth >= 900,
                              onDailyTap: () =>
                                  _openPeriodDetails('Today PnL', helper.today),
                              onWeeklyTap: () => _openPeriodDetails(
                                'This Week PnL',
                                helper.weekStart,
                              ),
                              onMonthlyTap: () => _openPeriodDetails(
                                'This Month PnL',
                                helper.monthStart,
                              ),
                            ),
                          ]),
                          _section(1, 'Capital & returns', [
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _capitalTotal(
                                  'Total deposits',
                                  helper.totalDeposits,
                                  CapitalReasonEnum.DEPOSIT,
                                ),
                                _capitalTotal(
                                  'Total withdrawals',
                                  helper.totalWithdraws,
                                  CapitalReasonEnum.WITHDRAW,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _pair(
                              wide,
                              CapitalGrowthChart(
                                data: helper.capitalOverTime(),
                              ),
                              WeeklyPnlChart(weeklyData: helper.weeklyPnl()),
                            ),
                          ]),
                          _section(
                            2,
                            'Trading performance',
                            [
                              TradeStatsRow(
                                analytics: analytics,
                                loading: _isTradesLoading,
                              ),
                              const SizedBox(height: 20),
                              _pair(
                                wide,
                                StrategyPerformanceChart(
                                  data: analytics.pnlByStrategy(),
                                  loading: _isTradesLoading,
                                ),
                                SessionPerformanceChart(
                                  data: analytics.pnlBySession(),
                                  loading: _isTradesLoading,
                                ),
                              ),
                            ],
                            subtitle: _isTradesLoading || _trades.isEmpty
                                ? null
                                : 'Based on the last ${_trades.length} trades',
                          ),
                          _section(3, 'Planning & discipline', [
                            _pair(
                              wide,
                              DashboardNoteStrip(
                                title: 'Reminder',
                                icon: Icons.lightbulb_outline,
                                accent: _reminderAccent(context),
                                loading: _isNotesLoading,
                                text: _notes.isEmpty
                                    ? 'No reminders yet'
                                    : _notes[_currentNoteIndex].text,
                                index: _currentNoteIndex,
                                count: _notes.length,
                                onNavigate: (delta) => setState(
                                  () => _currentNoteIndex =
                                      (_currentNoteIndex + delta) %
                                      _notes.length,
                                ),
                              ),
                              DashboardNoteStrip(
                                title: 'Strict rule',
                                icon: Icons.rule_folder_outlined,
                                accent: _ruleAccent(context),
                                loading: _isRulesLoading,
                                text: _rules.isEmpty
                                    ? 'No strict rules yet'
                                    : _rules[_currentRuleIndex].text,
                                index: _currentRuleIndex,
                                count: _rules.length,
                                onNavigate: (delta) => setState(
                                  () => _currentRuleIndex =
                                      (_currentRuleIndex + delta) %
                                      _rules.length,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const GoalsProgressSection(),
                            const SizedBox(height: 20),
                            PlannerDashboardSection(wide: wide),
                          ]),
                          _section(
                            4,
                            'Expenses & history',
                            [
                              ExpenseSummaryChart(
                                data: expenseHelper.totalByReason(),
                                total: expenseHelper.totalSpent,
                                loading: _isExpensesLoading,
                              ),
                              const SizedBox(height: 20),
                              WeeklyHistoryTable(
                                weeks: _showAllWeeks
                                    ? weeks
                                    : weeks.take(6).toList(),
                              ),
                              if (weeks.length > 6)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => setState(
                                      () => _showAllWeeks = !_showAllWeeks,
                                    ),
                                    child: Text(
                                      _showAllWeeks
                                          ? 'Show recent 6 weeks'
                                          : 'View all ${weeks.length} weeks',
                                    ),
                                  ),
                                ),
                            ],
                            subtitle:
                                'Expenses are tracked separately from capital and P&L',
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
