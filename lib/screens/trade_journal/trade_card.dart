import 'package:flutter/material.dart';

import '../../enums/trade_direction_enum.dart';
import '../../models/asset_model.dart';
import 'trade_draft.dart';

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
                    if (v != null) {
                      draft.signal = v;
                      onChanged();
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<Asset>(
                    value: assets.contains(draft.asset) ? draft.asset : null,
                    items: assets
                        .map((a) => DropdownMenuItem(
                      value: a,
                      child: Text('${a.symbol} • ${a.name}'),
                    ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        draft.asset = v;
                        onChanged();
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Pair'),
                  ),
                ),
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
                Expanded(
                  child: Text(
                      'Pips: ${draft.pips.toStringAsFixed(1)}'), // always safe
                ),
                Expanded(
                  child: Text(
                    'P/L: \$${draft.profit.toStringAsFixed(2)}',
                    style: TextStyle(
                        color: draft.profit >= 0 ? Colors.green : Colors.red),
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
