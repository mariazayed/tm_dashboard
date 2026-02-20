import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tm_dashboard/screens/capital_management/weekly_pnl_chart.dart';

import '../../enums/capital_reason_enum.dart';
import '../../models/capital_model.dart';
import '../../services/capital_service.dart';
import 'capital_list.dart';
import 'summary_data.dart';
import 'summary_section.dart';

class CapitalManagementScreen extends StatefulWidget {
  const CapitalManagementScreen({super.key});

  @override
  State<CapitalManagementScreen> createState() =>
      _CapitalManagementScreenState();
}

class _CapitalManagementScreenState extends State<CapitalManagementScreen> {
  bool _loading = true;
  List<CapitalModel> _capitals = [];

  @override
  void initState() {
    super.initState();
    _fetchCapitals();
  }

  Future<void> _fetchCapitals() async {
    setState(() => _loading = true);

    _capitals = await CapitalService.getAll();

    setState(() => _loading = false);
  }

  List<CapitalModel> _filterByDateRange({
    required DateTime from,
    required DateTime to,
  }) {
    return _capitals.where((c) {
      final inRange = !c.dateTime.isBefore(from) && !c.dateTime.isAfter(to);

      final isPnl =
          c.reason == CapitalReasonEnum.PROFIT ||
          c.reason == CapitalReasonEnum.LOSS;

      return inRange && isPnl;
    }).toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  void _openWeeklyPnlDetails() {
    final start = _week;
    final end = DateTime.now();

    final filtered = _filterByDateRange(from: start, to: end);

    _openPnlBottomSheet(
      title: "This Week PnL",
      from: start,
      to: end,
      data: filtered,
    );
  }

  void _openMonthlyPnlDetails() {
    final start = _month;
    final end = DateTime.now();

    final filtered = _filterByDateRange(from: start, to: end);

    _openPnlBottomSheet(
      title: "This Month PnL",
      from: start,
      to: end,
      data: filtered,
    );
  }

  void _openPnlBottomSheet({
    required String title,
    required DateTime from,
    required DateTime to,
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

                  /// Drag Handle
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

                  Expanded(child: CapitalList(capitals: data)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// ------------------------------
  /// Calculations
  /// ------------------------------

  double _sum({required DateTime from, CapitalReasonEnum? filter}) {
    return _capitals
        .where((c) => c.dateTime.isAfter(from))
        .where((c) => filter == null || c.reason == filter)
        .fold(0.0, (a, b) => a + b.amount);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Monday 00:00 of current week
  DateTime get _week {
    final now = DateTime.now();

    // weekday: Monday = 1 ... Sunday = 7
    final difference = now.weekday - DateTime.monday;

    final monday = now.subtract(Duration(days: difference));

    return DateTime(monday.year, monday.month, monday.day);
  }

  /// First day of current month 00:00
  DateTime get _month {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// ------------------------------
  /// Actions
  /// ------------------------------

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

  void _openTodayPnlDetails() {
    final start = _today;
    final end = DateTime.now();

    final filtered = _filterByDateRange(from: start, to: end);

    _openPnlBottomSheet(
      title: "Today PnL",
      from: start,
      to: end,
      data: filtered,
    );
  }

  /// ------------------------------
  /// UI
  /// ------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capital Overview')),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                      ),
                      child: Column(
                        children: [
                          SummarySection(
                            daily: _summary(_today),
                            weekly: _summary(_week),
                            monthly: _summary(_month),
                            wide: isWide,
                            onDailyTap: _openTodayPnlDetails,
                            onWeeklyTap: _openWeeklyPnlDetails,
                            onMonthlyTap: _openMonthlyPnlDetails,
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              _CapitalStatCard(
                                title: "Total Deposits",
                                value: _totalDeposits,
                                color: Colors.green.shade500,
                                icon: Icons.south_west_rounded,
                                onTap: () => _openFilteredCapitalDialog(
                                  CapitalReasonEnum.DEPOSIT,
                                ),
                              ),
                              const SizedBox(width: 16),
                              _CapitalStatCard(
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

                          WeeklyPnlChart(weeklyData: _weeklyPnl()),

                          const SizedBox(height: 24),

                          // WeeklyPnlTable(
                          //   profit: _weeklyProfit,
                          //   loss: _weeklyLoss,
                          // ),
                          WeeklyHistoryTable(weeks: _allWeeklyBreakdown()),

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

  List<WeeklyBreakdown> _allWeeklyBreakdown() {
    final Map<DateTime, WeeklyBreakdown> weekly = {};

    for (final c in _capitals) {
      if (c.reason != CapitalReasonEnum.PROFIT &&
          c.reason != CapitalReasonEnum.LOSS) {
        continue;
      }

      // Monday start of that week
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

  SummaryData _summary(DateTime from) {
    final profits = _sum(from: from, filter: CapitalReasonEnum.PROFIT);
    final losses = _sum(from: from, filter: CapitalReasonEnum.LOSS);

    return SummaryData(profits: profits, losses: losses, pnl: profits + losses);
  }

  List<MapEntry<DateTime, double>> _weeklyPnl() {
    final Map<DateTime, double> weekly = {};

    for (final c in _capitals) {
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

  double get _totalDeposits {
    return _capitals
        .where((c) => c.reason == CapitalReasonEnum.DEPOSIT)
        .fold(0.0, (a, b) => a + b.amount);
  }

  double get _totalWithdraws {
    return _capitals
        .where((c) => c.reason == CapitalReasonEnum.WITHDRAW)
        .fold(0.0, (a, b) => a + b.amount);
  }

  double get _weeklyProfit {
    return _capitals
        .where(
          (c) =>
              c.reason == CapitalReasonEnum.PROFIT &&
              !c.dateTime.isBefore(_week),
        )
        .fold(0.0, (a, b) => a + b.amount);
  }

  double get _weeklyLoss {
    return _capitals
        .where(
          (c) =>
              c.reason == CapitalReasonEnum.LOSS && !c.dateTime.isBefore(_week),
        )
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
}

class _CapitalStatCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final double value;
  final Color color;
  final IconData icon;

  const _CapitalStatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  blurRadius: 20,
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Icon + Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.12),
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                /// Animated Value
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return Text(
                      val.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WeeklyPnlTable extends StatelessWidget {
  final double profit;
  final double loss;

  const WeeklyPnlTable({super.key, required this.profit, required this.loss});

  @override
  Widget build(BuildContext context) {
    final net = profit + loss;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title
          Text(
            "Weekly Breakdown",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 20),

          /// Table Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Type", style: TextStyle(fontWeight: FontWeight.w600)),
              Text("Amount", style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),

          const Divider(height: 28),

          /// Profit Row
          _buildRow(
            label: "Profit",
            value: profit,
            color: Colors.green.shade500,
          ),

          const SizedBox(height: 14),

          /// Loss Row
          _buildRow(label: "Loss", value: loss, color: Colors.red.shade400),

          const Divider(height: 28),

          /// Net Row
          _buildRow(
            label: "Net",
            value: net,
            color: net >= 0 ? Colors.green.shade600 : Colors.red.shade600,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required double value,
    required Color color,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class WeeklyBreakdown {
  final DateTime weekStart;
  double profit = 0;
  double loss = 0;

  WeeklyBreakdown({required this.weekStart});

  double get net => profit + loss;
}

class WeeklyHistoryTable extends StatelessWidget {
  final List<WeeklyBreakdown> weeks;

  const WeeklyHistoryTable({super.key, required this.weeks});

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No weekly data")),
      );
    }

    final formatter = DateFormat('MMM d');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Weekly Performance",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 20),

          /// Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(child: Text("Week")),
              Expanded(child: Text("Profit")),
              Expanded(child: Text("Loss")),
              Expanded(child: Text("Net")),
            ],
          ),

          const Divider(height: 28),

          ...weeks.map((week) {
            final weekEnd = week.weekStart.add(const Duration(days: 6));

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${formatter.format(week.weekStart)} - ${formatter.format(weekEnd)}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      week.profit.toStringAsFixed(2),
                      style: TextStyle(
                        color: Colors.green.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      week.loss.toStringAsFixed(2),
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      week.net.toStringAsFixed(2),
                      style: TextStyle(
                        color: week.net >= 0
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
