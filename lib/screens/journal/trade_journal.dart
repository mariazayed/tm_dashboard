import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// =======================
/// DATA MODELS
/// =======================

enum TradeSignal { buy, sell }

class TradeJournalRecord {
  final DateTime entryDateTime;
  final DateTime exitDateTime;
  final TradeSignal signal;
  final double entryPrice;
  final double exitPrice;
  final double lot;
  final double sl;
  final double tp;
  final String pair;
  final String notes;
  final double pips;
  final double profit;

  TradeJournalRecord({
    required this.entryDateTime,
    required this.exitDateTime,
    required this.signal,
    required this.entryPrice,
    required this.exitPrice,
    required this.lot,
    required this.sl,
    required this.tp,
    required this.pair,
    required this.notes,
    required this.pips,
    required this.profit,
  });
}

class TradeDraft {
  TradeSignal signal = TradeSignal.buy;
  double entryPrice = 0;
  double exitPrice = 0;
  double lot = 0.01;
  double sl = 0;
  double tp = 0;
  String notes = '';
  String pair = 'XAUUSD';

  double pips = 0;
  double profit = 0;
}

/// =======================
/// MAIN PAGE
/// =======================

class TradeJournalScreen extends StatefulWidget {
  const TradeJournalScreen({super.key});

  @override
  State<TradeJournalScreen> createState() => _TradeJournalScreenState();
}

class _TradeJournalScreenState extends State<TradeJournalScreen> {
  final List<TradeJournalRecord> records = [];

  void _openAddJournal() async {
    final result = await showModalBottomSheet<List<TradeJournalRecord>>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddJournalSheet(),
    );

    if (result != null) {
      setState(() => records.addAll(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TJ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddJournal,
        icon: const Icon(Icons.add),
        label: const Text('Add Journal'),
      ),
      body: records.isEmpty
          ? const Center(child: Text('No trades yet'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (_, i) {
          final r = records[i];
          return Card(
            child: ListTile(
              title: Text('${r.pair} • ${r.signal.name.toUpperCase()}'),
              subtitle: Text(
                'Pips: ${r.pips.toStringAsFixed(1)} | '
                    'P/L: \$${r.profit.toStringAsFixed(2)}',
              ),
            ),
          );
        },
      ),
    );
  }
}

/// =======================
/// ADD JOURNAL SHEET
/// =======================

class AddJournalSheet extends StatefulWidget {
  const AddJournalSheet({super.key});

  @override
  State<AddJournalSheet> createState() => _AddJournalSheetState();
}

class _AddJournalSheetState extends State<AddJournalSheet> {
  DateTime? entryDateTime;
  DateTime? exitDateTime;

  final List<TradeDraft> drafts = [TradeDraft()];

  static const double pipSizeXAU = 0.01;

  void _recalculate(TradeDraft d) {
    final diff = d.exitPrice - d.entryPrice;
    final rawPips = diff / pipSizeXAU;
    d.pips = d.signal == TradeSignal.buy ? rawPips : -rawPips;
    d.profit = d.pips * d.lot;
  }

  Future<void> _pickDateTime(bool isEntry) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      final dt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      isEntry ? entryDateTime = dt : exitDateTime = dt;
    });
  }

  void _submit() {
    if (entryDateTime == null || exitDateTime == null) return;

    final result = drafts.map((d) {
      return TradeJournalRecord(
        entryDateTime: entryDateTime!,
        exitDateTime: exitDateTime!,
        signal: d.signal,
        entryPrice: d.entryPrice,
        exitPrice: d.exitPrice,
        lot: d.lot,
        sl: d.sl,
        tp: d.tp,
        pair: d.pair,
        notes: d.notes,
        pips: d.pips,
        profit: d.profit,
      );
    }).toList();

    print("result $result");

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        children: [
          /// Header with X button
          Row(
            children: [
              const Text(
                'New Trade Journal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDateTime(true),
                  child: Text(
                    entryDateTime == null
                        ? 'Entry DateTime'
                        : DateFormat('dd MMM yyyy HH:mm')
                        .format(entryDateTime!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDateTime(false),
                  child: Text(
                    exitDateTime == null
                        ? 'Exit DateTime'
                        : DateFormat('dd MMM yyyy HH:mm')
                        .format(exitDateTime!),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          ...drafts.map(
                (d) => _TradeDraftCard(
              draft: d,
              onChanged: () => setState(() => _recalculate(d)),
              onRemove: drafts.length > 1
                  ? () => setState(() => drafts.remove(d))
                  : null,
            ),
          ),

          TextButton.icon(
            onPressed: () => setState(() => drafts.add(TradeDraft())),
            icon: const Icon(Icons.add),
            label: const Text('Add Trade'),
          ),

          const SizedBox(height: 24),

          FilledButton(
            onPressed: _submit,
            child: const Text('Submit Journal'),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// TRADE CARD
/// =======================

class _TradeDraftCard extends StatelessWidget {
  final TradeDraft draft;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _TradeDraftCard({
    required this.draft,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                DropdownButton<TradeSignal>(
                  value: draft.signal,
                  items: TradeSignal.values
                      .map(
                        (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name.toUpperCase()),
                    ),
                  )
                      .toList(),
                  onChanged: (v) {
                    draft.signal = v!;
                    onChanged();
                  },
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: draft.pair,
                  items: const [
                    DropdownMenuItem(value: 'XAUUSD', child: Text('XAUUSD')),
                  ],
                  onChanged: (_) {},
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                  ),
              ],
            ),
            _num('Entry Price', (v) {
              draft.entryPrice = v;
              onChanged();
            }),
            _num('Exit Price', (v) {
              draft.exitPrice = v;
              onChanged();
            }),
            _num('Lot', (v) {
              draft.lot = v;
              onChanged();
            }),
            _num('SL', (v) => draft.sl = v),
            _num('TP', (v) => draft.tp = v),

            /// Calculated fields
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pips: ${draft.pips.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'P/L: \$${draft.profit.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: draft.profit >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            TextField(
              decoration: const InputDecoration(labelText: 'Notes'),
              onChanged: (v) => draft.notes = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _num(String label, Function(double) onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }
}
