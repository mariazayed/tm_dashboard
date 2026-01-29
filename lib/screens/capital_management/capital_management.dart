import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tm_dashboard/services/capital_service.dart';

import '../../enums/capital_reason_enum.dart';
import '../../models/capital_model.dart';

/// ------------------------------
/// Capital Overview Screen
/// ------------------------------
/// - Fetches all capital records from server
/// - Lists them chronologically
/// - Shows Daily / Weekly / Monthly summary
/// - Deposit & Withdraw actions with dialogs

class CapitalManagementScreen extends StatefulWidget {
  const CapitalManagementScreen({super.key});

  @override
  State<CapitalManagementScreen> createState() => _CapitalManagementScreenState();
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

  /// ------------------------------
  /// Calculations
  /// ------------------------------

  double _sum({required DateTime from, CapitalReasonEnum? filter}) {
    return _capitals
        .where((c) => c.dateTime.isAfter(from))
        .where((c) => filter == null || c.reason == filter)
        .fold(0.0, (a, b) => a + b.amount);
  }

  DateTime get _today => DateTime.now().subtract(const Duration(days: 1));
  DateTime get _week => DateTime.now().subtract(const Duration(days: 7));
  DateTime get _month => DateTime.now().subtract(const Duration(days: 30));

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
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                          initialTime:
                          TimeOfDay.fromDateTime(selectedDateTime),
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
                    final value =
                    double.tryParse(amountController.text);

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
                      {
                        ...model.toJson(),
                      }
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
            icon: const Icon(Icons.add),
            label: const Text('Deposit'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'withdraw',
            backgroundColor: Colors.redAccent,
            onPressed: () => _openCapitalDialog(CapitalReasonEnum.WITHDRAW),
            icon: const Icon(Icons.remove),
            label: const Text('Withdraw'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SummarySection(
                  daily: _summary(_today),
                  weekly: _summary(_week),
                  monthly: _summary(_month),
                  wide: isWide,
                ),
                const SizedBox(height: 24),
                Expanded(child: _CapitalList(capitals: _capitals)),
              ],
            ),
          );
        },
      ),
    );
  }

  SummaryData _summary(DateTime from) {
    final profits = _sum(from: from, filter: CapitalReasonEnum.PROFIT);
    final losses = _sum(from: from, filter: CapitalReasonEnum.LOSS);

    return SummaryData(
      profits: profits,
      losses: losses,
      pnl: profits + losses,
    );
  }
}

/// ------------------------------
/// Summary Models & Widgets
/// ------------------------------

class SummaryData {
  final double profits;
  final double losses;
  final double pnl;

  SummaryData({required this.profits, required this.losses, required this.pnl});
}

class _SummarySection extends StatelessWidget {
  final SummaryData daily;
  final SummaryData weekly;
  final SummaryData monthly;
  final bool wide;

  const _SummarySection({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'TODAY', data: daily),
          _SummaryRow(label: 'WEEK', data: weekly),
          _SummaryRow(label: 'MONTH', data: monthly),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final SummaryData data;

  const _SummaryRow({
    required this.label,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final pnlColor =
    data.pnl > 0 ? Colors.green : data.pnl < 0 ? Colors.red : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(letterSpacing: 1.2),
            ),
          ),
          _ValueCell(
            value: data.profits,
            color: Colors.green,
          ),
          _ValueCell(
            value: data.losses,
            color: Colors.red,
          ),
          _ValueCell(
            value: data.pnl,
            color: pnlColor,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  final double value;
  final Color color;
  final bool bold;

  const _ValueCell({
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        value.toStringAsFixed(2),
        textAlign: TextAlign.right,
        style: TextStyle(
          color: color,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ElegantSummaryCard extends StatelessWidget {
  final String title;
  final SummaryData data;

  const _ElegantSummaryCard({
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final pnlColor = data.pnl >= 0 ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            pnlColor.withOpacity(0.15),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: pnlColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),

          /// PnL
          Text(
            data.pnl.toStringAsFixed(2),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: pnlColor,
            ),
          ),
          const SizedBox(height: 8),

          /// Breakdown
          Row(
            children: [
              _MiniStat(
                label: 'Profit',
                value: data.profits,
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _MiniStat(
                label: 'Loss',
                value: data.losses,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}


/// ------------------------------
/// Capital List
/// ------------------------------

class _CapitalList extends StatelessWidget {
  final List<CapitalModel> capitals;

  const _CapitalList({required this.capitals});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: capitals.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
      itemBuilder: (_, i) {
        final c = capitals[i];
        final isPositive = c.amount >= 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Main row
              Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      _formatDate(c.dateTime),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      c.reason.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      c.notes ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      c.amount.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [
                          FontFeature.tabularFigures()
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              /// Notes (expanded view)
              if (c.notes != null && c.notes!.length > 40)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 110),
                  child: Text(
                    c.notes!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

