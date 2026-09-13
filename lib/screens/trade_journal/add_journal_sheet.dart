import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tm_dashboard/models/strategy_model.dart';

import '../../enums/trade_direction_enum.dart';
import '../../models/asset_model.dart';
import '../../services/trade_service.dart';
import 'classes/trade_draft.dart';
import 'trade_card.dart';

class AddJournalSheet extends StatefulWidget {
  final List<Asset> assets;
  final List<Strategy> strategies;

  const AddJournalSheet({
    super.key,
    required this.assets,
    required this.strategies,
  });

  @override
  State<AddJournalSheet> createState() => _AddJournalSheetState();
}

class _AddJournalSheetState extends State<AddJournalSheet> {
  DateTime? entryDateTime;
  DateTime? exitDateTime;
  late List<TradeDraft> drafts;

  // True while _submit()'s POST /trade is in flight -- disables the Submit
  // button and swaps its label for a spinner so there's no dead period
  // where the sheet looks unresponsive while waiting on the server.
  bool _submitting = false;

  static const double xauPipSize = 0.1;

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
    d.profit = d.pips * d.lot * 10;
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
    if (_submitting) return;
    if (entryDateTime == null || exitDateTime == null || drafts.isEmpty) return;

    final payload = drafts
        .map(
          (d) => d.toJson(
            entryDateTime: entryDateTime!,
            exitDateTime: exitDateTime!,
          ),
        )
        .toList();

    setState(() => _submitting = true);
    try {
      await TradeService.create(payload);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save journal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        children: [
          // Header
          Row(
            children: [
              const Text(
                'New Trade Journal',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Date pickers
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDateTime(true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    child: Text(
                      entryDateTime == null
                          ? 'Entry DateTime'
                          : DateFormat(
                              'dd MMM yyyy HH:mm',
                            ).format(entryDateTime!),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDateTime(false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8,
                    ),
                    child: Text(
                      exitDateTime == null
                          ? 'Exit DateTime'
                          : DateFormat(
                              'dd MMM yyyy HH:mm',
                            ).format(exitDateTime!),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Trade cards
          ...drafts.map(
            (d) => Padding(
              key: ValueKey(d.id),
              padding: const EdgeInsets.only(bottom: 28),
              child: TradeCard(
                draft: d,
                assets: widget.assets,
                strategies: widget.strategies,
                onChanged: () => setState(() => _recalc(d)),
                onRemove: drafts.length > 1
                    ? () => setState(() => drafts.remove(d))
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Add trade
          TextButton.icon(
            onPressed: widget.assets.isEmpty
                ? null
                : () => setState(
                    () => drafts.add(TradeDraft(asset: drafts.first.asset)),
                  ),
            icon: const Icon(Icons.add),
            label: const Text('Add Trade'),
          ),

          const SizedBox(height: 32),

          // Submit
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Journal'),
            ),
          ),
        ],
      ),
    );
  }
}
