import '../../widgets/responsive_row.dart';
import 'package:flutter/material.dart';
import 'package:tm_dashboard/models/strategy_model.dart';

import '../../enums/trade_direction_enum.dart';
import '../../models/asset_model.dart';
import '../../theme/app_theme.dart';
import 'classes/trade_draft.dart';

class TradeCard extends StatefulWidget {
  final TradeDraft draft;
  final List<Asset> assets;
  final List<Strategy> strategies;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const TradeCard({
    super.key,
    required this.draft,
    required this.assets,
    required this.strategies,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<TradeCard> createState() => _TradeCardState();
}

class _TradeCardState extends State<TradeCard> {
  late final TextEditingController entryCtrl;
  late final TextEditingController exitCtrl;
  late final TextEditingController lotCtrl;
  late final TextEditingController slCtrl;
  late final TextEditingController tpCtrl;
  late final TextEditingController notesCtrl;

  @override
  void initState() {
    super.initState();
    entryCtrl = TextEditingController(text: widget.draft.entryPrice.toString());
    exitCtrl = TextEditingController(text: widget.draft.exitPrice.toString());
    lotCtrl = TextEditingController(text: widget.draft.lot.toString());
    slCtrl = TextEditingController(text: widget.draft.sl.toString());
    tpCtrl = TextEditingController(text: widget.draft.tp.toString());
    notesCtrl = TextEditingController(text: widget.draft.notes ?? '');
  }

  @override
  void dispose() {
    entryCtrl.dispose();
    exitCtrl.dispose();
    lotCtrl.dispose();
    slCtrl.dispose();
    tpCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Direction + Asset (unchanged)
            ResponsiveRow(
              children: [
                DropdownButton<TradeDirectionEnum>(
                  value: d.signal,
                  items: TradeDirectionEnum.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      d.signal = v;
                      widget.onChanged();
                    }
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<Asset>(
                    isExpanded: true,
value: widget.assets.contains(d.asset) ? d.asset : null,
                    items: widget.assets
                        .map(
                          (a) => DropdownMenuItem(
                            value: a,
                            child: Text('${a.symbol} • ${a.name}'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        d.asset = v;
                        widget.onChanged();
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Pair'),
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onRemove,
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // IMPORTANT: don't use Expanded here; TradeCard is typically inside a ListView
            DropdownButtonFormField<Strategy>(
              isExpanded: true,
value: widget.strategies.contains(d.strategy) ? d.strategy : null,
              items: widget.strategies
                  .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  d.strategy = v;
                  widget.onChanged();
                }
              },
              decoration: const InputDecoration(labelText: 'Strategy'),
            ),

            const SizedBox(height: 20),

            _num('Entry Price', entryCtrl, (v) {
              d.entryPrice = v;
              widget.onChanged();
            }),
            const SizedBox(height: 16),
            _num('Exit Price', exitCtrl, (v) {
              d.exitPrice = v;
              widget.onChanged();
            }),

            const SizedBox(height: 20),

            _num('Lot', lotCtrl, (v) {
              d.lot = v;
              widget.onChanged();
            }),
            const SizedBox(height: 16),
            _num('SL', slCtrl, (v) => d.sl = v),
            const SizedBox(height: 16),
            _num('TP', tpCtrl, (v) => d.tp = v),

            const SizedBox(height: 24),

            ResponsiveRow(
              children: [
                Expanded(child: Text('Pips: ${d.pips.toStringAsFixed(1)}')),
                Expanded(
                  child: Text(
                    'P/L: \$${d.profit.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: d.profit >= 0
                          ? context.semanticColors.profit
                          : context.semanticColors.loss,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            TextField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
              onChanged: (v) => d.notes = v,
            ),
          ],
        ),
      ),
    );
  }

  Widget _num(
    String label,
    TextEditingController ctrl,
    Function(double) onChanged,
  ) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }
}
