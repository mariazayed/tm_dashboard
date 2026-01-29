import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/trade_direction_enum.dart';
import '../../models/asset_model.dart';
import '../../services/trade_service.dart';
import 'trade_card.dart';
import 'trade_draft.dart';

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
    if (widget.assets.isEmpty) {
      drafts = [];
    } else {
      final defaultAsset = widget.assets.firstWhere(
            (a) => a.symbol == 'XAUUSD',
        orElse: () => widget.assets.first,
      );
      drafts = [TradeDraft(asset: defaultAsset)];
    }
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
      if (entry) {
        entryDateTime = dt;
      } else {
        exitDateTime = dt;
      }
    });
  }

  Future<void> _submit() async {
    if (entryDateTime == null || exitDateTime == null || drafts.isEmpty) return;

    final payload = drafts
        .map((d) => d.toJson(
      entryDateTime: entryDateTime!,
      exitDateTime: exitDateTime!,
    ))
        .toList();

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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDateTime(true),
                  child: Text(entryDateTime == null
                      ? 'Entry DateTime'
                      : DateFormat('dd MMM yyyy HH:mm').format(entryDateTime!)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDateTime(false),
                  child: Text(exitDateTime == null
                      ? 'Exit DateTime'
                      : DateFormat('dd MMM yyyy HH:mm').format(exitDateTime!)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...drafts.map((d) => TradeCard(
            draft: d,
            assets: widget.assets,
            onChanged: () => setState(() => _recalc(d)),
            onRemove: drafts.length > 1
                ? () => setState(() => drafts.remove(d))
                : null,
          )),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: widget.assets.isEmpty
                ? null
                : () => setState(() =>
                drafts.add(TradeDraft(asset: drafts.first.asset))),
            icon: const Icon(Icons.add),
            label: const Text('Add Trade'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submit,
            child: const Text('Submit Journal'),
          ),
        ],
      ),
    );
  }
}