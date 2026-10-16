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
    this.cashBalanceCents = 0,
  });

  final PerformanceModel performance;
  final VoidCallback onRefresh;
  final bool refreshing;

  /// Months in a row with a contribution; hidden when null.
  final int? currentStreak;

  /// Unspent contribution cash, which remains part of the portfolio but has
  /// not been invested in shares.
  final int cashBalanceCents;

  static String gainText(PerformanceModel p, {int cashBalanceCents = 0}) {
    final gainCents = p.gainCents + cashBalanceCents + p.feesCents;
    final sign = gainCents > 0 ? '+' : '';
    final money = '$sign${Money.format(gainCents, p.currency)}';
    final shareCostCents = p.investedCents - cashBalanceCents - p.feesCents;
    final pct = shareCostCents <= 0 ? null : gainCents / shareCostCents * 100;
    return pct == null ? money : '$money ($sign${pct.toStringAsFixed(2)}%)';
  }

  static String priceNote(PerformanceModel p) {
    final asOf = p.priceAsOf;
    if (!p.hasContributions) return 'Add a contribution to see performance';
    if (p.isMixed) {
      if (!p.priceFromCache) {
        return 'Some funds have no market prices yet: they are valued at your last buy price. Refresh prices to update.';
      }
      final date = asOf == null ? '' : DateFormat.yMMMd().format(asOf);
      return p.stale
          ? 'Latest prices as of $date (out of date, refresh prices)'
          : 'Latest prices as of $date';
    }
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
    final gainCents =
        performance.gainCents + cashBalanceCents + performance.feesCents;
    final gainText = PerformanceCard.gainText(
      performance,
      cashBalanceCents: cashBalanceCents,
    );
    final gainColor = gainCents > 0
        ? colors.profit
        : gainCents < 0
        ? colors.loss
        : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio value',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        Money.format(
                          performance.valueCents + cashBalanceCents,
                          performance.currency,
                        ),
                        key: const Key('portfolio-value'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _GainBadge(text: gainText, color: gainColor),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              priceNote(performance),
              key: const Key('price-note'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: performance.stale
                    ? colors.warning
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: refreshing ? null : onRefresh,
              icon: refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 18),
              label: Text(refreshing ? 'Refreshing…' : 'Refresh prices'),
            ),
            const Divider(height: 28),
            Wrap(
              spacing: 32,
              runSpacing: 14,
              children: [
                _Figure(
                  'Invested',
                  Money.format(performance.investedCents, performance.currency),
                ),
                _Figure(
                  'Fees',
                  Money.format(performance.feesCents, performance.currency),
                ),
                _Figure(
                  'Gain',
                  gainText,
                  color: gainColor,
                  key: const Key('gain-figure'),
                ),
                if (performance.averageCost != null)
                  _Figure('Avg cost', '\$${_averageCost.toStringAsFixed(2)}'),
                // Shares of different funds cannot be added into one meaningful number.
                if (!performance.isMixed)
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
            if (performance.isMixed) ...[
              const SizedBox(height: 12),
              _FundBreakdown(
                holdings: performance.holdings,
                currency: performance.currency,
              ),
            ],
          ],
        ),
      ),
    );
  }

  double get _averageCost {
    if (performance.shares <= 0) return performance.averageCost ?? 0;
    final investedInSharesCents =
        performance.investedCents - cashBalanceCents - performance.feesCents;
    return investedInSharesCents / 100 / performance.shares;
  }
}

class _GainBadge extends StatelessWidget {
  const _GainBadge({required this.text, required this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              color == null
                  ? Icons.remove_rounded
                  : color == context.semanticColors.profit
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              size: 17,
              color: tint,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
              ),
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

/// Each fund's value, gain and share of the portfolio against its target.
class _FundBreakdown extends StatelessWidget {
  const _FundBreakdown({required this.holdings, required this.currency});

  final List<HoldingPerformanceModel> holdings;
  final String currency;

  /// How far off target, in percentage points, before a fund is flagged.
  static const driftLimit = 5.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.semanticColors;
    return Column(
      key: const Key('fund-breakdown'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('By fund', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final h in holdings)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              key: Key('fund-row-${h.holdingId}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(h.ticker, style: theme.textTheme.titleSmall),
                    Text(Money.format(h.valueCents, currency)),
                    Text(
                      _gain(h),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: h.gainCents > 0
                            ? colors.profit
                            : h.gainCents < 0
                            ? colors.loss
                            : null,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(_allocation(h), style: theme.textTheme.bodySmall),
                    if (h.driftPoints != null &&
                        h.driftPoints!.abs() > driftLimit)
                      Text(
                        '${h.driftPoints!.abs().toStringAsFixed(1)} points '
                        '${h.driftPoints! > 0 ? 'over' : 'under'} target',
                        key: Key('drift-${h.holdingId}'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _gain(HoldingPerformanceModel h) {
    if (h.investedCents == 0) return 'nothing bought yet';
    final sign = h.gainCents > 0 ? '+' : '';
    final money = '$sign${Money.format(h.gainCents, currency)}';
    final pct = h.gainPercent;
    return pct == null ? money : '$money ($sign${pct.toStringAsFixed(2)}%)';
  }

  String _allocation(HoldingPerformanceModel h) {
    final target =
        '${h.targetPct.toStringAsFixed(h.targetPct % 1 == 0 ? 0 : 1)}%';
    final now = h.allocationPct;
    return now == null
        ? 'target $target'
        : '${now.toStringAsFixed(1)}% of the portfolio · target $target';
  }
}
