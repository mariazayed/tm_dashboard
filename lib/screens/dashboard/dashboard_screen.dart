import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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
import 'capital_stat_card.dart';
import 'classes/capital_dashboard_helper.dart';
import 'classes/expense_dashboard_helper.dart';
import 'classes/trade_analytics_helper.dart';
import 'expense_summary_chart.dart';
import 'goals_progress_section.dart';
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
  Timer? _notesTimer;
  Timer? _rulesTimer;

  // Recent-trade history backing the Trade Performance section (stat row +
  // PnL-by-strategy/session + mistake frequency). Bounded fetch -- see
  // TradeService.getRecentForAnalytics -- not the full auto-imported
  // history.
  List<Trade> _trades = [];
  bool _isTradesLoading = true;

  // Backing the Expenses summary chart. Expenses is a manually-maintained
  // standalone log (not auto-imported like Trades), so this is the same
  // full, paged-under-the-hood fetch used for the Capital ledger rather
  // than a bounded/recent one.
  List<ExpenseModel> _expenses = [];
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

  TradeAnalyticsHelper get analytics => TradeAnalyticsHelper(_trades);

  ExpenseDashboardHelper get expenseHelper => ExpenseDashboardHelper(_expenses);

  @override
  void initState() {
    super.initState();
    _fetchCapitals();
    _fetchNotes();
    _fetchRules();
    _fetchTrades();
    _fetchExpenses();
  }

  @override
  void dispose() {
    _notesTimer?.cancel();
    _rulesTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isNotesLoading = true);

    try {
      // Paged transport under the hood instead of one unbounded GET.
      final response = await ReminderNotesService.getAllPaged();
      if (response.isNotEmpty) {
        final notes = List.of(response)..shuffle(Random());

        setState(() {
          _notes = notes;
          _currentNoteIndex = 0;
          _isNotesLoading = false;
        });

        if (_notes.isNotEmpty) {
          _notesTimer?.cancel();
          _notesTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
            setState(() {
              _currentNoteIndex = (_currentNoteIndex + 1) % _notes.length;
            });
          });
        }
      } else {
        setState(() => _isNotesLoading = false);
      }
    } catch (e) {
      setState(() => _isNotesLoading = false);
      debugPrint('Error fetching notes: $e');
    }
  }

  Future<void> _fetchRules() async {
    setState(() => _isRulesLoading = true);

    try {
      // Paged transport under the hood instead of one unbounded GET.
      final response = await StrictRulesService.getAllPaged();
      if (response.isNotEmpty) {
        final rules = List.of(response)..shuffle(Random());

        setState(() {
          _rules = rules;
          _currentRuleIndex = 0;
          _isRulesLoading = false;
        });

        if (_rules.isNotEmpty) {
          _rulesTimer?.cancel();
          _rulesTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
            setState(() {
              _currentRuleIndex = (_currentRuleIndex + 1) % _rules.length;
            });
          });
        }
      } else {
        setState(() => _isRulesLoading = false);
      }
    } catch (e) {
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

  double get _totalWithdraws {
    return _capitals
        .where((c) => c.reason == CapitalReasonEnum.WITHDRAW)
        .fold(0.0, (a, b) => a + b.amount);
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

  Widget _buildDashboardNoteCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required bool loading,
    required bool isEmpty,
    required String text,
    required int index,
    required int total,
    required bool isNotesCard,
  }) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return MouseRegion(
          onEnter: (_) {
            setLocalState(() => isHovered = true);

            if (isNotesCard) {
              _notesTimer?.cancel();
            } else {
              _rulesTimer?.cancel();
            }
          },
          onExit: (_) {
            setLocalState(() => isHovered = false);

            // Cancel any existing timer first -- onExit can fire more than
            // once without a matching onEnter in between (these animated
            // hover regions can re-layout under the pointer), and without
            // this guard each spurious exit stacked another live
            // Timer.periodic on top of the old one. Every stacked timer
            // kept firing setState -> rebuilding this card, so hovering it
            // repeatedly made the dashboard progressively heavier (more
            // concurrent timers) the longer it stayed open.
            if (isNotesCard && _notes.isNotEmpty) {
              _notesTimer?.cancel();
              _notesTimer = Timer.periodic(
                const Duration(seconds: 6),
                (_) => setState(() {
                  _currentNoteIndex = (_currentNoteIndex + 1) % _notes.length;
                }),
              );
            }

            if (!isNotesCard && _rules.isNotEmpty) {
              _rulesTimer?.cancel();
              _rulesTimer = Timer.periodic(
                const Duration(seconds: 6),
                (_) => setState(() {
                  _currentRuleIndex = (_currentRuleIndex + 1) % _rules.length;
                }),
              );
            }
          },
          child: AnimatedScale(
            scale: isHovered ? 1.015 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: 200, // <-- FIXED HEIGHT (keeps both cards aligned)
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                // Solid surface + shadow, matching every other card on this
                // page -- the previous frosted/blurred glass look had
                // nothing colorful behind it to blur, so it just read as a
                // flat gray box with no depth or identity.
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: isHovered
                      ? accentColor.withOpacity(0.35)
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                    offset: const Offset(0, 10),
                  ),
                  if (isHovered)
                    BoxShadow(
                      blurRadius: 32,
                      spreadRadius: 1,
                      color: accentColor.withOpacity(0.18),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Large faint watermark icon for texture -- purely
                    // decorative, clipped to the card's rounded corners.
                    Positioned(
                      right: -14,
                      bottom: -14,
                      child: Icon(
                        icon,
                        size: 96,
                        color: accentColor.withOpacity(0.06),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor.withOpacity(0.12),
                              ),
                              child: Icon(icon, size: 18, color: accentColor),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            if (total > 1)
                              _buildNoteDots(total, index, accentColor),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Expanded(
                          child: loading
                              ? _buildNoteShimmer(context)
                              : isEmpty
                              ? _buildNoteEmptyState(context, icon, isNotesCard)
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(
                                      milliseconds: 500,
                                    ),
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.08, 0),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      text,
                                      key: ValueKey(text),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        height: 1.6,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Small pill-dot pagination indicator -- replaces the old plain "1/3"
  /// text with something that reads at a glance and matches the rest of
  /// this dashboard's visual language (accent-colored, not just gray text).
  Widget _buildNoteDots(int total, int index, Color accentColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(left: 4),
            width: i == index ? 14 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i == index ? accentColor : accentColor.withOpacity(0.25),
            ),
          ),
      ],
    );
  }

  Widget _buildNoteEmptyState(BuildContext context, IconData icon, bool isNotesCard) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: colorScheme.outline),
          const SizedBox(height: 8),
          Text(
            isNotesCard ? "No reminders yet" : "No strict rules yet",
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteShimmer(BuildContext context) {
    final semantic = context.semanticColors;
    final surface = Theme.of(context).colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: semantic.shimmerBase,
      highlightColor: semantic.shimmerHighlight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 16,
            width: 220,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
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
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: Column(
                  children: [
                    isWide
                        ? Row(
                            children: [
                              Expanded(
                                child: _buildDashboardNoteCard(
                                  title: "Reminder",
                                  icon: Icons.lightbulb_outline,
                                  accentColor: _reminderAccent(context),
                                  loading: _isNotesLoading,
                                  isEmpty: _notes.isEmpty,
                                  text: _notes.isNotEmpty
                                      ? _notes[_currentNoteIndex].text
                                      : "",
                                  index: _currentNoteIndex,
                                  total: _notes.length,
                                  isNotesCard: true,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildDashboardNoteCard(
                                  title: "Strict Rule",
                                  icon: Icons.rule_folder_outlined,
                                  accentColor: _ruleAccent(context),
                                  loading: _isRulesLoading,
                                  isEmpty: _rules.isEmpty,
                                  text: _rules.isNotEmpty
                                      ? _rules[_currentRuleIndex].text
                                      : "",
                                  index: _currentRuleIndex,
                                  total: _rules.length,
                                  isNotesCard: false,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildDashboardNoteCard(
                                title: "Reminder",
                                icon: Icons.lightbulb_outline,
                                accentColor: _reminderAccent(context),
                                loading: _isNotesLoading,
                                isEmpty: _notes.isEmpty,
                                text: _notes.isNotEmpty
                                    ? _notes[_currentNoteIndex].text
                                    : "",
                                index: _currentNoteIndex,
                                total: _notes.length,
                                isNotesCard: true,
                              ),
                              const SizedBox(height: 24),
                              _buildDashboardNoteCard(
                                title: "Strict Rule",
                                icon: Icons.rule_folder_outlined,
                                accentColor: _ruleAccent(context),
                                loading: _isRulesLoading,
                                isEmpty: _rules.isEmpty,
                                text: _rules.isNotEmpty
                                    ? _rules[_currentRuleIndex].text
                                    : "",
                                index: _currentRuleIndex,
                                total: _rules.length,
                                isNotesCard: false,
                              ),
                            ],
                          ),

                    const SizedBox(height: 24),

                    // Previously built but never wired into this screen.
                    const GoalsProgressSection(),

                    SummarySection(
                      daily: helper.summaryFrom(helper.today),
                      weekly: helper.summaryFrom(helper.weekStart),
                      monthly: helper.summaryFrom(helper.monthStart),
                      wide: isWide,
                      onDailyTap: () =>
                          _openPeriodDetails("Today PnL", helper.today),
                      onWeeklyTap: () =>
                          _openPeriodDetails("This Week PnL", helper.weekStart),
                      onMonthlyTap: () => _openPeriodDetails(
                        "This Month PnL",
                        helper.monthStart,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: CapitalStatCard(
                            title: "Total Deposits",
                            value: helper.totalDeposits,
                            color: context.semanticColors.profit,
                            icon: Icons.south_west_rounded,
                            onTap: () => _openFilteredCapitalDialog(
                              CapitalReasonEnum.DEPOSIT,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CapitalStatCard(
                            title: "Total Withdraws",
                            value: _totalWithdraws,
                            color: context.semanticColors.loss,
                            icon: Icons.north_east_rounded,
                            onTap: () => _openFilteredCapitalDialog(
                              CapitalReasonEnum.WITHDRAW,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    CapitalGrowthChart(data: helper.capitalOverTime()),

                    const SizedBox(height: 24),

                    WeeklyPnlChart(weeklyData: helper.weeklyPnl()),

                    const SizedBox(height: 24),

                    // --- Expenses: the standalone expense log (see the
                    // Expenses feature writeup) is never netted against
                    // Capital/PnL above -- this is a pure display summary. ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildSectionHeader(
                        context,
                        title: "Expenses",
                        subtitle: _isExpensesLoading || _expenses.isEmpty
                            ? null
                            : "${_expenses.length} expense${_expenses.length == 1 ? '' : 's'} logged",
                      ),
                    ),

                    const SizedBox(height: 16),

                    ExpenseSummaryChart(
                      data: expenseHelper.totalByReason(),
                      total: expenseHelper.totalSpent,
                      loading: _isExpensesLoading,
                    ),

                    const SizedBox(height: 24),

                    // --- Trade Performance: computed from actual Trade
                    // history (TradeAnalyticsHelper), as opposed to
                    // everything above this line, which is derived from the
                    // capital ledger only. ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildSectionHeader(
                        context,
                        title: "Trade Performance",
                        subtitle: _isTradesLoading || _trades.isEmpty
                            ? null
                            : "Based on the last ${_trades.length} trade${_trades.length == 1 ? '' : 's'}",
                      ),
                    ),

                    const SizedBox(height: 16),

                    TradeStatsRow(
                      analytics: analytics,
                      loading: _isTradesLoading,
                    ),

                    const SizedBox(height: 24),

                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Expanded(
                              //   child: StrategyPerformanceChart(
                              //     data: analytics.pnlByStrategy(),
                              //     loading: _isTradesLoading,
                              //   ),
                              // ),
                              // const SizedBox(width: 24),
                              Expanded(
                                child: SessionPerformanceChart(
                                  data: analytics.pnlBySession(),
                                  loading: _isTradesLoading,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              StrategyPerformanceChart(
                                data: analytics.pnlByStrategy(),
                                loading: _isTradesLoading,
                              ),
                              const SizedBox(height: 24),
                              SessionPerformanceChart(
                                data: analytics.pnlBySession(),
                                loading: _isTradesLoading,
                              ),
                            ],
                          ),

                    const SizedBox(height: 24),

                    // MistakeTagChart(
                    //   data: analytics.mistakeTagFrequency(),
                    //   loading: _isTradesLoading,
                    // ),

                    // const SizedBox(height: 24),

                    // WeeklyPnlTable(
                    //   profit: _weeklyProfit,
                    //   loss: _weeklyLoss,
                    // ),
                    WeeklyHistoryTable(weeks: helper.weeklyBreakdown()),

                    const SizedBox(height: 24),

                    // Expanded(child: CapitalList(capitals: _capitals)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
