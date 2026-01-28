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
      appBar: AppBar(
        title: const Text('Trade Journal'),
      ),
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
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                '${r.pair} • ${r.signal.name.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Pips: ${r.pips.toStringAsFixed(1)} | '
                    'P/L: \$${r.profit.toStringAsFixed(2)}',
              ),
              trailing: Text(
                DateFormat('dd MMM').format(r.entryDateTime),
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

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      isEntry ? entryDateTime = dt : exitDateTime = dt;
    });
  }

  double _calcPips(TradeDraft d) {
    const pipValue = 0.01; // XAUUSD
    final diff = d.exitPrice - d.entryPrice;
    final rawPips = diff / pipValue;
    return d.signal == TradeSignal.buy ? rawPips : -rawPips;
  }

  double _calcProfit(double pips, double lot) {
    return pips * lot;
  }

  void _submit() {
    if (entryDateTime == null || exitDateTime == null) return;

    final result = drafts.map((d) {
      final pips = _calcPips(d);
      final profit = _calcProfit(pips, d.lot);

      return TradeJournalRecord(
        entryDateTime: entryDateTime!,
        exitDateTime: exitDateTime!,
        signal: d.signal,
        entryPrice: d.entryPrice,
        exitPrice: d.exitPrice,
        lot: d.lot,
        sl: d.sl,
        tp: d.tp,
        pair: 'XAUUSD',
        notes: d.notes,
        pips: pips,
        profit: profit,
      );
    }).toList();

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            children: [
              const Text(
                'New Trade Journal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              /// Entry / Exit time
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

              /// Trades list
              ...drafts.asMap().entries.map(
                    (e) => _TradeDraftCard(
                  key: ValueKey(e.key),
                  draft: e.value,
                  onRemove: drafts.length > 1
                      ? () => setState(() => drafts.removeAt(e.key))
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
      },
    );
  }
}

/// =======================
/// TRADE DRAFT CARD
/// =======================

class _TradeDraftCard extends StatelessWidget {
  final TradeDraft draft;
  final VoidCallback? onRemove;

  const _TradeDraftCard({
    super.key,
    required this.draft,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
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
                  onChanged: (v) => draft.signal = v!,
                ),
                const Spacer(),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                  ),
              ],
            ),
            _numField('Entry Price', (v) => draft.entryPrice = v),
            _numField('Exit Price', (v) => draft.exitPrice = v),
            _numField('Lot', (v) => draft.lot = v),
            _numField('SL', (v) => draft.sl = v),
            _numField('TP', (v) => draft.tp = v),
            TextField(
              decoration: const InputDecoration(labelText: 'Notes'),
              onChanged: (v) => draft.notes = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(String label, Function(double) onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }
}
