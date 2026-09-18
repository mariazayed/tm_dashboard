import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_theme.dart';
import 'dashboard_bar_row.dart';

/// "PnL by Strategy" card -- net profit/loss per strategy, from
/// `TradeAnalyticsHelper.pnlByStrategy()`, largest-magnitude first.
///
/// Bars use the app's existing green/red profit-loss convention (not a
/// generic diverging color pair) for consistency with every other PnL
/// surface in the app (Calendar heatmap, WeeklyPnlChart, CapitalGrowthChart).
class StrategyPerformanceChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final bool loading;
  final int maxVisible;

  const StrategyPerformanceChart({
    super.key,
    required this.data,
    this.loading = false,
    this.maxVisible = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return _buildShimmer(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "No strategy data yet",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            ..._rows(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Icon(
            Icons.insights,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "PnL by Strategy",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  List<Widget> _rows(BuildContext context) {
    final semantic = context.semanticColors;
    final visible = data.take(maxVisible).toList();
    final maxAbs = visible
        .map((e) => e.value.abs())
        .fold(0.0, (a, b) => a > b ? a : b);
    final remaining = data.length - visible.length;

    return [
      for (final entry in visible)
        DashboardBarRow(
          label: entry.key,
          valueText:
              "${entry.value >= 0 ? '+' : ''}${entry.value.toStringAsFixed(2)}",
          fraction: maxAbs == 0 ? 0 : entry.value.abs() / maxAbs,
          color: entry.value >= 0 ? semantic.profit : semantic.loss,
        ),
      if (remaining > 0)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            "+$remaining more strateg${remaining == 1 ? 'y' : 'ies'}",
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
    ];
  }

  Widget _buildShimmer(BuildContext context) {
    final semantic = context.semanticColors;

    return Shimmer.fromColors(
      baseColor: semantic.shimmerBase,
      highlightColor: semantic.shimmerHighlight,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}
