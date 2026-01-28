import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tm_dashboard/enums/trade_direction_enum.dart';
import 'package:tm_dashboard/models/trade_model.dart';
import 'package:tm_dashboard/services/trade_service.dart';

import '../../models/asset_model.dart';
import '../../services/asset_service.dart';

class TradeJournal {
  final DateTime entryDateTime;
  final DateTime exitDateTime;
  final List<TradeModel> trades;

  TradeJournal({
    required this.entryDateTime,
    required this.exitDateTime,
    required this.trades,
  });

  double get totalProfit =>
      trades.fold(0, (sum, t) => sum + t.profit);
}

List<TradeJournal> groupTrades(List<TradeModel> trades) {
  final map = <String, List<TradeModel>>{};

  for (final t in trades) {
    final key =
        '${t.entryDateTime.toIso8601String()}_${t.exitDateTime.toIso8601String()}';
    map.putIfAbsent(key, () => []).add(t);
  }

  return map.values.map((group) {
    return TradeJournal(
      entryDateTime: group.first.entryDateTime,
      exitDateTime: group.first.exitDateTime,
      trades: group,
    );
  }).toList();
}


class TradeDraft {
  Asset asset;
  TradeDirectionEnum signal = TradeDirectionEnum.LONG;
  double entryPrice = 0;
  double exitPrice = 0;
  double lot = 0.01;
  double sl = 0;
  double tp = 0;
  String notes = '';
  double pips = 0;
  double profit = 0;

  TradeDraft({required this.asset});

  Map<String, dynamic> toJson({
    required DateTime entryDateTime,
    required DateTime exitDateTime,
  }) {
    return {
      'entryDateTime': entryDateTime.toIso8601String(),
      'exitDateTime': exitDateTime.toIso8601String(),
      'asset': asset.id,
      'direction': signal.value,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'lotSize': lot,
      'slPrice': sl,
      'tpPrice': tp,
      'notes': notes,
      'pips': pips,
      'pnl': profit,
    };
  }
}

/// =======================
/// MAIN PAGE
/// =======================

class JournalsScreen extends StatefulWidget {
  final List<Asset> assets;
  const JournalsScreen({super.key, required this.assets});

  @override
  State<JournalsScreen> createState() => _JournalsScreenState();
}

class _JournalsScreenState extends State<JournalsScreen> {
  late Future<List<TradeJournal>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<TradeJournal>> _load() async {
    final trades = await TradeService.fetchTrades();
    return groupTrades(trades);
  }

  Future<void> _openAddJournal() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AddJournalSheet(assets: widget.assets),
    );

    setState(() {
      future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Journals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _openAddJournal,
          ),
        ],
      ),
      body: FutureBuilder<List<TradeJournal>>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final journals = snapshot.data!;
          if (journals.isEmpty) {
            return const Center(child: Text('No journals yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: journals.length,
            itemBuilder: (_, i) => _JournalCard(journal: journals[i]),
          );
        },
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final TradeJournal journal;
  const _JournalCard({required this.journal});

  @override
  Widget build(BuildContext context) {
    final profitColor =
    journal.totalProfit >= 0 ? Colors.green : Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          DateFormat('dd MMM yyyy HH:mm')
              .format(journal.entryDateTime),
        ),
        subtitle: Text(
          'Trades: ${journal.trades.length} • '
              'P/L: ${journal.totalProfit.toStringAsFixed(2)} \$',
          style: TextStyle(color: profitColor),
        ),
        children: journal.trades.map((t) {
          return ListTile(
            title: Text('${t.asset.symbol} ${t.direction.name.toUpperCase()}'),
            subtitle: Text(
              'Entry ${t.entryPrice} → Exit ${t.exitPrice}',
            ),
            trailing: Text(
              '${t.profit.toStringAsFixed(2)} \$',
              style: TextStyle(
                color: t.profit >= 0 ? Colors.green : Colors.red,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


class TradeJournalScreen extends StatefulWidget {
  const TradeJournalScreen({super.key});

  @override
  State<TradeJournalScreen> createState() => _TradeJournalScreenState();
}

class _TradeJournalScreenState extends State<TradeJournalScreen> {
  late final Future<List<Asset>> futureAssets;

  @override
  void initState() {
    super.initState();

// Ensure the field is ALWAYS initialized, even if fetchAssets throws synchronously.
    futureAssets = () {
      try {
        return AssetService.fetchAssets();
      } catch (e, st) {
        return Future<List<Asset>>.error(e, st);
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Asset>>(
      future: futureAssets,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Failed to load assets:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final assets = snapshot.data ?? const <Asset>[];

        return JournalsScreen(assets: assets);
      },
    );
  }
}

/// =======================
/// ADD JOURNAL SHEET
/// =======================

class AddJournalSheet extends StatefulWidget {
  final List<Asset> assets;

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

  void _recalc(TradeDraft d) {
    if (d.asset.symbol != 'XAUUSD') {
      d.pips = 0;
      d.profit = 0;
      return;
    }
    final diff = d.exitPrice - d.entryPrice;
    final raw = diff / xauPipSize;
    d.pips = d.signal == TradeDirectionEnum.LONG ? raw : -raw;
    d.profit = d.pips * d.lot;
  }

  Future<void> _pickDateTime(bool entry) async {
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
      entry ? entryDateTime = dt : exitDateTime = dt;
    });
  }

  Future<void> _submit() async {
    if (entryDateTime == null || exitDateTime == null) return;

    final payload = drafts.map((d) => d.toJson(
        entryDateTime: entryDateTime!,
        exitDateTime: exitDateTime!,
      )).toList();


    print("payload $payload");

    await TradeService.create(payload);
    Navigator.pop(context);
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

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDateTime(true),
                  child: Text(entryDateTime == null
                      ? 'Entry DateTime'
                      : DateFormat('dd MMM yyyy HH:mm')
                      .format(entryDateTime!)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDateTime(false),
                  child: Text(exitDateTime == null
                      ? 'Exit DateTime'
                      : DateFormat('dd MMM yyyy HH:mm')
                      .format(exitDateTime!)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          ...drafts.map((d) => _TradeCard(
            draft: d,
            assets: widget.assets,
            onChanged: () => setState(() => _recalc(d)),
            onRemove: drafts.length > 1
                ? () => setState(() => drafts.remove(d))
                : null,
          )),

          TextButton.icon(
            onPressed: () => setState(() => drafts.add(
              TradeDraft(asset: drafts.first.asset),
            )),
            icon: const Icon(Icons.add),
            label: const Text('Add Trade'),
          ),

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

class _TradeCard extends StatelessWidget {
  final TradeDraft draft;
  final List<Asset> assets;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const _TradeCard({
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
                DropdownButton<TradeDirectionEnum>(
                  value: draft.signal,
                  items: TradeDirectionEnum.values
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.name.toUpperCase()),
                  ))
                      .toList(),
                  onChanged: (v) {
                    draft.signal = v!;
                    onChanged();
                  },
                ),
                const SizedBox(width: 12),
          DropdownButtonFormField<Asset>(
            value: draft.asset,
            items: assets.map((a) {
              return DropdownMenuItem(
                value: a,
                child: Text('${a.symbol} • ${a.name}'),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                draft.asset = v;
                onChanged();
              }
            },
            decoration: const InputDecoration(labelText: 'Pair'),
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
            Row(
              children: [
                Expanded(child: Text('Pips: ${draft.pips.toStringAsFixed(1)}')),
                Expanded(
                  child: Text(
                    'P/L: \$${draft.profit.toStringAsFixed(2)}',
                    style: TextStyle(
                        color:
                        draft.profit >= 0 ? Colors.green : Colors.red),
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
