import 'package:flutter/material.dart';

import '../../enums/capital_reason_enum.dart';
import '../../models/capital_model.dart';
import '../../services/capital_service.dart';
import '../dashboard/capital_list.dart';
import '../dashboard/capital_stat_card.dart';

/// Standalone screen for recording and reviewing capital movements
/// (deposits and withdraws). The creation buttons used to live on the
/// Dashboard as floating action buttons; they now live here instead.
class CapitalScreen extends StatefulWidget {
  const CapitalScreen({super.key});

  @override
  State<CapitalScreen> createState() => _CapitalScreenState();
}

class _CapitalScreenState extends State<CapitalScreen> {
  // Deposits/withdraws are user-initiated (not auto-imported like trades),
  // so the full filtered list is fetched a page at a time (see
  // CapitalService.getDepositsAndWithdrawsPaged) rather than exposed as an
  // open-ended infinite scroll -- that keeps "Total Deposits/Withdraws"
  // below accurate (a partial sum while more pages are still loading would
  // be actively misleading for a money total) while still avoiding
  // CapitalService.getAll()'s old cost: pulling the *entire* capital
  // table -- including a PROFIT/LOSS row for every trade ever imported --
  // over the network just to throw away everything except DEPOSIT/WITHDRAW.

  List<CapitalModel> _capitals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCapitals();
  }

  Future<void> _fetchCapitals() async {
    setState(() => _isLoading = true);

    final capitals = await CapitalService.getDepositsAndWithdrawsPaged();

    if (!mounted) return;

    setState(() {
      _capitals = capitals;
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deposits & Withdraws')),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: CapitalStatCard(
                          title: "Total Deposits",
                          value: _totalDeposits,
                          color: Colors.green.shade500,
                          icon: Icons.south_west_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CapitalStatCard(
                          title: "Total Withdraws",
                          value: _totalWithdraws,
                          color: Colors.red.shade400,
                          icon: Icons.north_east_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _capitals.isEmpty
                      ? const Center(
                          child: Text('No deposits or withdraws yet'),
                        )
                      : CapitalList(capitals: _capitals),
                ),
              ],
            ),
    );
  }
}
