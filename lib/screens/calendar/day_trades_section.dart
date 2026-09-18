import 'package:flutter/material.dart';

import '../../models/trade_model.dart';
import '../../theme/app_theme.dart';
import '../trade_list/trade_row_tile.dart';

/// The "Trades" section of the day-detail dialog: a summary strip (trade
/// count, net P&L, win rate) followed by the day's trades, reusing the same
/// [TradeRowTile] the Trades screen uses so tapping one opens its familiar
/// detail sheet.
class DayTradesSection extends StatelessWidget {
  final List<Trade> trades;

  const DayTradesSection({super.key, required this.trades});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final netPnl = trades.fold<double>(0.0, (sum, t) => sum + t.profit);
    final wins = trades.where((t) => t.profit > 0).length;
    final winRate = trades.isEmpty ? 0.0 : (wins / trades.length) * 100;
    final pnlColor = netPnl >= 0 ? semantic.profit : semantic.loss;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Trades", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),

        if (trades.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              "No trades recorded for this day.",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                _SummaryStat(label: "Trades", value: "${trades.length}"),
                _divider(context),
                _SummaryStat(
                  label: "Net P&L",
                  value:
                      "${netPnl >= 0 ? '+' : ''}${netPnl.toStringAsFixed(2)}",
                  color: pnlColor,
                ),
                _divider(context),
                _SummaryStat(
                  label: "Win rate",
                  value: "${winRate.toStringAsFixed(0)}%",
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...trades.map((t) => TradeRowTile(trade: t)),
        ],
      ],
    );
  }

  Widget _divider(BuildContext context) => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: Theme.of(context).colorScheme.outlineVariant,
  );
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
