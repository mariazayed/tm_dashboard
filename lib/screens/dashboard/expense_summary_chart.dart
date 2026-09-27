import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_theme.dart';
import 'dashboard_bar_row.dart';

/// "Expenses by Reason" card -- total amount spent per expense reason, from
/// `ExpenseDashboardHelper.totalByReason()`, largest first.
///
/// Expenses is a standalone log (never netted against Capital or PnL
/// anywhere else in the app), so this is a single-series magnitude
/// breakdown -- no polarity to encode -- and uses one consistent hue,
/// distinct from the green/red profit/loss convention and from the amber
/// already claimed by MistakeTagChart.
class ExpenseSummaryChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final double total;
  final bool loading;
  final int maxVisible;

  const ExpenseSummaryChart({
    super.key,
    required this.data,
    required this.total,
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
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                "No expenses recorded yet",
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
    final violet = context.semanticColors.violet;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: violet.withValues(alpha: 0.12),
          ),
          child: Icon(Icons.receipt_long_outlined, size: 18, color: violet),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "Expenses by Reason",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (data.isNotEmpty)
          Text(
            "Total: ${total.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  List<Widget> _rows(BuildContext context) {
    final violet = context.semanticColors.violet;
    final visible = data.take(maxVisible).toList();
    final maxValue = visible.fold(0.0, (a, b) => a > b.value ? a : b.value);
    final remaining = data.length - visible.length;

    return [
      for (final entry in visible)
        DashboardBarRow(
          label: entry.key,
          valueText: entry.value.toStringAsFixed(2),
          fraction: maxValue == 0 ? 0 : entry.value / maxValue,
          color: violet,
        ),
      if (remaining > 0)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            "+$remaining more reason${remaining == 1 ? '' : 's'}",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
