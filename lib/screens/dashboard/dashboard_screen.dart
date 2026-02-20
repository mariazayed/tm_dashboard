import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../enums/capital_reason_enum.dart';
import '../../models/capital_model.dart';
import '../../models/reminder_note_model.dart';
import '../../models/strict_rule_model.dart';
import '../../services/capital_service.dart';
import '../../services/reminder_notes_service.dart';
import '../../services/strict_rules_service.dart';
import 'capital_list.dart';
import 'capital_stat_card.dart';
import 'classes/capital_dashboard_helper.dart';
import 'notebook_lines_painter.dart';
import 'summary_section.dart';
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

  // Modern light colors for sticky notes
  final List<Color> _colors = [
    Colors.yellow.shade100,
    Colors.blue.shade50,
    Colors.green.shade50,
    Colors.pink.shade50,
    Colors.orange.shade50,
    Colors.purple.shade50,
  ];

  CapitalDashboardHelper get helper {
    final h = _helper;
    if (h != null) return h;

    final created = CapitalDashboardHelper(_capitals);

    _helper = created;
    return created;
  }

  @override
  void initState() {
    super.initState();
    _fetchCapitals();
    _fetchNotes();
    _fetchRules();
  }

  @override
  void dispose() {
    _notesTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isNotesLoading = true);

    try {
      final response = await ReminderNotesService.getAll();
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
      final response = await StrictRulesService.getAll();
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

  Widget _buildSection({
    required String title,
    required bool loading,
    required bool isEmpty,
    required String text,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Section Title
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        loading
            ? const Center(child: CircularProgressIndicator())
            : isEmpty
            ? const Text("No data available")
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey(text),
                  padding: const EdgeInsets.all(24),
                  height: 280,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 30,
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: NotebookLinesPainter()),
                      ),
                      Center(
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Future<void> _fetchCapitals() async {
    final capitals = await CapitalService.getAll();

    if (!mounted) return;

    setState(() {
      _capitals = capitals;
      _helper = null;
    });
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
                      color: Colors.grey.shade400,
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
                          ? Colors.green.shade500
                          : Colors.red.shade400,
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

  Future<void> _openCapitalDialog(CapitalReasonEnum reason) async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime selectedDateTime = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                reason == CapitalReasonEnum.DEPOSIT ? 'Deposit' : 'Withdraw',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Amount
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        hintText: 'Enter amount',
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// DateTime Picker
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDateTime,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );

                        if (date == null) return;

                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );

                        if (time == null) return;

                        setState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date & Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(selectedDateTime.toString()),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Notes
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Optional notes...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final value = double.tryParse(amountController.text);

                    if (value == null) return;

                    final model = CapitalModel(
                      dateTime: selectedDateTime,
                      reason: reason,
                      amount: value,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );

                    await CapitalService.create([
                      {...model.toJson()},
                    ]);

                    if (mounted) Navigator.pop(context);
                    _fetchCapitals();
                  },
                  child: const Text('Confirm'),
                ),
              ],
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
                      color: Colors.grey.shade400,
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

  @override
  Widget build(BuildContext context) {
    final Color currentNoteColor = _colors[_currentNoteIndex % _colors.length];
    final Color currentRuleColor = _colors[_currentRuleIndex % _colors.length];

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'deposit',
            onPressed: () => _openCapitalDialog(CapitalReasonEnum.DEPOSIT),
            icon: const Icon(Icons.trending_up), // deposit (capital in)
            label: const Text('Deposit'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'withdraw',
            backgroundColor: Colors.redAccent,
            onPressed: () => _openCapitalDialog(CapitalReasonEnum.WITHDRAW),
            icon: const Icon(Icons.trending_down),
            // withdraw (capital out)
            label: const Text('Withdraw'),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                                child: _buildSection(
                                  title: "Reminder",
                                  loading: _isNotesLoading,
                                  isEmpty: _notes.isEmpty,
                                  text: _notes.isNotEmpty
                                      ? _notes[_currentNoteIndex].text
                                      : "",
                                  color: currentNoteColor,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildSection(
                                  title: "Strict Rule",
                                  loading: _isRulesLoading,
                                  isEmpty: _rules.isEmpty,
                                  text: _rules.isNotEmpty
                                      ? _rules[_currentRuleIndex].text
                                      : "",
                                  color: currentRuleColor,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildSection(
                                title: "Reminder",
                                loading: _isNotesLoading,
                                isEmpty: _notes.isEmpty,
                                text: _notes.isNotEmpty
                                    ? _notes[_currentNoteIndex].text
                                    : "",
                                color: currentNoteColor,
                              ),
                              const SizedBox(height: 24),
                              _buildSection(
                                title: "Strict Rule",
                                loading: _isRulesLoading,
                                isEmpty: _rules.isEmpty,
                                text: _rules.isNotEmpty
                                    ? _rules[_currentRuleIndex].text
                                    : "",
                                color: currentRuleColor,
                              ),
                            ],
                          ),

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
                        CapitalStatCard(
                          title: "Total Deposits",
                          value: helper.totalDeposits,
                          color: Colors.green.shade500,
                          icon: Icons.south_west_rounded,
                          onTap: () => _openFilteredCapitalDialog(
                            CapitalReasonEnum.DEPOSIT,
                          ),
                        ),
                        const SizedBox(width: 16),
                        CapitalStatCard(
                          title: "Total Withdraws",
                          value: _totalWithdraws,
                          color: Colors.red.shade400,
                          icon: Icons.north_east_rounded,
                          onTap: () => _openFilteredCapitalDialog(
                            CapitalReasonEnum.WITHDRAW,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    WeeklyPnlChart(weeklyData: helper.weeklyPnl()),

                    const SizedBox(height: 24),

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
