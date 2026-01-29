import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../enums/capital_reason_enum.dart';
import '../../models/capital_model.dart';
import '../../services/capital_service.dart';
import 'summary_data.dart';
import 'summary_section.dart';

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
            icon: const Icon(Icons.trending_up), // deposit (capital in)
            label: const Text('Deposit'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'withdraw',
            backgroundColor: Colors.redAccent,
            onPressed: () => _openCapitalDialog(CapitalReasonEnum.WITHDRAW),
            icon: const Icon(Icons.trending_down), // withdraw (capital out)
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

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SummarySection(
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
/// Capital List
/// ------------------------------

class _CapitalList extends StatelessWidget {
  final List<CapitalModel> capitals;

  const _CapitalList({required this.capitals});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: capitals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final c = capitals[i];
        final isPositive = c.amount >= 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPositive
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header row
              Row(
                children: [
                  Icon(
                    isPositive
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c.reason.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    c.amount.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              /// Date
              Text(
                c.dateTime.toLocal().toString(),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.grey),
              ),

              /// Notes (optional)
              if (c.notes != null && c.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    c.notes!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

