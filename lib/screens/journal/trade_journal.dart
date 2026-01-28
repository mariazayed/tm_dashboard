import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// =======================
/// SERVER MODELS
/// =======================

class TradingAsset {
  final String id;
  final String name;
  final String symbol;

  TradingAsset({
    required this.id,
    required this.name,
    required this.symbol,
  });
}

/// =======================
/// DOMAIN MODELS
/// =======================

enum TradeSignal { buy, sell }

class TradeJournalRecord {
  final DateTime entryDateTime;
  final DateTime exitDateTime;

  final String assetId;
  final String assetName;
  final String assetSymbol;

  final TradeSignal signal;
  final double entryPrice;
  final double exitPrice;
  final double lot;
  final double sl;
  final double tp;
  final String notes;

  final double pips;
  final double profit;

  TradeJournalRecord({
    required this.entryDateTime,
    required this.exitDateTime,
    required this.assetId,
    required this.assetName,
    required this.assetSymbol,
    required this.signal,
    required this.entryPrice,
    required this.exitPrice,
    required this.lot,
    required this.sl,
    required this.tp,
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

  TradingAsset asset;

  double pips = 0;
  double profit = 0;

  TradeDraft({required this.asset});
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

  /// Simulated server response
  final List<TradingAsset> assets = [
    TradingAsset(id: '1', name: 'Gold', symbol: 'XAUUSD'),
    TradingAsset(id: '2', name: 'Euro / Dollar', symbol: 'EURUSD'),
    TradingAsset(id: '3', name: 'GBP / Dollar', symbol: 'GBPUSD'),
  ];

  void _openAddJournal() async {
    final result = await showModalBottomSheet<List<TradeJournalRecord>>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AddJournalSheet(assets: assets),
    );

    if (result != null) {
      setState(() => records.addAll(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trade Journal')),
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
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                '${r.assetSymbol} • ${r.signal.name.toUpperCase()}',
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
  final List<TradingAsset> assets;

  const AddJournalSheet({super.key, required this.assets});

  @override
  State<AddJournalSheet> createState() => _AddJournalSheetState();
}

class _AddJournalSheetState extends State<AddJournalSheet> {
  DateTime? entryDateTime;
  DateTime? exitDateTime;

  late List<TradeDraft> drafts;

  static const double xauPipSize = 0.01;

  @override
  void initState() {
    super.initState();
    final defaultAsset = widget.assets.firstWhere(
          (a) => a.symbol == 'XAUUSD',
      orElse: () => widget.assets.first,
    );
    drafts = [TradeDraft(asset: defaultAsset)];
  }

  void _recalculate(TradeDraft d) {
    if (d.asset.symbol != 'XAUUSD') {
      d.pips = 0;
      d.profit = 0;
      return;
    }

    final diff = d.exitPrice - d.entryPrice;
    final rawPips = diff / xauPipSize;

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
        assetId: d.asset.id,
        assetName: d.asset.name,
        assetSymbol: d.asset.symbol,
        signal: d.signal,
        entryPrice: d.entryPrice,
        exitPrice: d.exitPrice,
        lot: d.lot,
        sl: d.sl,
        tp: d.tp,
        notes: d.notes,
        pips: d.pips,
        profit: d.profit,
      );
    }).toList();

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
          /// Header
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
              assets: widget.assets,
              onChanged: () => setState(() => _recalculate(d)),
              onRemove: drafts.length > 1
                  ? () => setState(() => drafts.remove(d))
                  : null,
            ),
          ),

          TextButton.icon(
            onPressed: () => setState(() => drafts.add(
              TradeDraft(asset: drafts.first.asset),
            )),
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
/// TRADE DRAFT CARD
/// =======================

class _TradeDraftCard extends StatelessWidget {
  final TradeDraft draft;
  final List<TradingAsset> assets;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _TradeDraftCard({
    required this.draft,
    required this.assets,
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
                DropdownButton<TradingAsset>(
                  value: draft.asset,
                  items: assets
                      .map(
                        (a) => DropdownMenuItem(
                      value: a,
                      child: Text('${a.symbol} • ${a.name}'),
                    ),
                  )
                      .toList(),
                  onChanged: (v) {
                    draft.asset = v!;
                    onChanged();
                  },
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

            const SizedBox(height: 8),

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
                      color:
                      draft.profit >= 0 ? Colors.green : Colors.red,
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
