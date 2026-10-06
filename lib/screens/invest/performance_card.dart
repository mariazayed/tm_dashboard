import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/invest/money.dart';
import '../../models/invest/performance_model.dart';
import '../../theme/app_semantic_colors.dart';

/// Invested, value and gain at a glance, with an honest note about how fresh
/// the price is. [onRefresh] pulls new closes; [refreshing] disables it.
class PerformanceCard extends StatelessWidget {
  const PerformanceCard({
    super.key,
    required this.performance,
    required this.onRefresh,
    this.refreshing = false,
    this.currentStreak,
  });

  final PerformanceModel performance;
  final VoidCallback onRefresh;
  final bool refreshing;

  /// Months in a row with a contribution; hidden when null.
  final int? currentStreak;

  static String gainText(PerformanceModel p) {
    final sign = p.gainCents > 0 ? '+' : '';
    final money = '$sign${Money.format(p.gainCents, p.currency)}';
    final pct = p.gainPercent;
    return pct == null ? money : '$money ($sign${pct.toStringAsFixed(2)}%)';
  }

  static String priceNote(PerformanceModel p) {
    final asOf = p.priceAsOf;
    if (!p.hasContributions) return 'Add a contribution to see performance';
    if (!p.priceFromCache) {
      return 'No market prices yet: valued at your last buy price. Refresh prices to update.';
    }
    final date = asOf == null ? '' : DateFormat.yMMMd().format(asOf);
    final price = p.currentPrice?.toStringAsFixed(2) ?? '';
    return p.stale
        ? '${p.ticker} \$$price as of $date (out of date, refresh prices)'
        : '${p.ticker} \$$price as of $date';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.semanticColors;
    final gainColor = performance.gainCents > 0
        ? colors.profit
        : performance.gainCents < 0
        ? colors.loss
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _Figure(
                  'Invested',
                  Money.format(performance.investedCents, performance.currency),
                ),
                _Figure(
                  'Value',
                  Money.format(performance.valueCents, performance.currency),
                ),
                _Figure(
                  'Gain',
                  gainText(performance),
                  color: gainColor,
                  key: const Key('gain-figure'),
                ),
                if (performance.averageCost != null)
                  _Figure(
                    'Avg cost',
                    '\$${performance.averageCost!.toStringAsFixed(2)}',
                  ),
                _Figure(
                  'Shares',
                  performance.shares.toStringAsFixed(4),
                  key: const Key('shares-figure'),
                ),
                if (currentStreak != null)
                  _Figure(
                    'Month streak',
                    '$currentStreak',
                    key: const Key('streak-figure'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              priceNote(performance),
              key: const Key('price-note'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: performance.stale ? colors.warning : null,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: refreshing ? null : onRefresh,
              child: Text(refreshing ? 'Refreshing…' : 'Refresh prices'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value, {this.color, super.key});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
