import 'package:flutter/material.dart';

import '../../enums/trade_direction_enum.dart';
import '../../models/asset_model.dart';
import 'classes/trade_draft.dart';

class TradeCard extends StatelessWidget {
  final TradeDraft draft;
  final List<Asset> assets;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  const TradeCard({super.key,
    required this.draft,
    required this.assets,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Direction + Asset
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DropdownButton<TradeDirectionEnum>(
                  value: draft.signal,
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
                      draft.signal = v;
                      onChanged();
                    }
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<Asset>(
                    value: assets.contains(draft.asset) ? draft.asset : null,
                    items: assets
                        .map(
                          (a) => DropdownMenuItem(
                        value: a,
                        child: Text('${a.symbol} • ${a.name}'),
                      ),
                    )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        draft.asset = v;
                        onChanged();
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Pair',
                      isDense: true,
                    ),
                  ),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Prices
            _num('Entry Price', (v) {
              draft.entryPrice = v;
              onChanged();
            }),
            const SizedBox(height: 16),
            _num('Exit Price', (v) {
              draft.exitPrice = v;
              onChanged();
            }),

            const SizedBox(height: 20),

            // Position details
            _num('Lot', (v) {
              draft.lot = v;
              onChanged();
            }),
            const SizedBox(height: 16),
            _num('SL', (v) => draft.sl = v),
            const SizedBox(height: 16),
            _num('TP', (v) => draft.tp = v),

            const SizedBox(height: 24),

            // Pips & P/L
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pips: ${draft.pips.toStringAsFixed(1)}',
                  ),
                ),
                Expanded(
                  child: Text(
                    'P/L: \$${draft.profit.toStringAsFixed(2)}',
                    style: TextStyle(
                      color:
                      draft.profit >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Notes
            TextField(
              decoration: const InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
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
