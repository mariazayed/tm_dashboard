import 'package:flutter/material.dart';

import '../../enums/capital_reason_enum.dart';
import '../../models/capital_model.dart';
import '../../services/capital_service.dart';
import 'capital_list.dart';
import 'capital_stat_card.dart';
import 'classes/capital_dashboard_helper.dart';
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
