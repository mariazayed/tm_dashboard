import 'package:flutter/material.dart';

import '../../models/invest/money.dart';
import '../../models/invest/performance_model.dart';

class PortfolioAllocationCard extends StatelessWidget {
  const PortfolioAllocationCard({
    super.key,
    required this.performance,
    required this.onEdit,
  });

  final PerformanceModel performance;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holdings = [...performance.holdings]
      ..sort((a, b) => a.ticker.compareTo(b.ticker));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Portfolio allocation',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(onPressed: onEdit, child: const Text('Manage')),
              ],
            ),
            if (holdings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Add holdings and target percentages to see your allocation.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (var i = 0; i < holdings.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                _HoldingAllocationRow(
                  holding: holdings[i],
                  currency: performance.currency,
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _HoldingAllocationRow extends StatelessWidget {
  const _HoldingAllocationRow({required this.holding, required this.currency});

  final HoldingPerformanceModel holding;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actual = holding.allocationPct;
    final drift = holding.driftPoints;
    final isOffTarget = drift != null && drift.abs() > 5;
    final actualLabel = actual == null
        ? 'No allocation yet'
        : '${actual.toStringAsFixed(1)}%';
    final targetLabel =
        '${holding.targetPct.toStringAsFixed(holding.targetPct % 1 == 0 ? 0 : 1)}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                holding.name == null || holding.name!.isEmpty
                    ? holding.ticker
                    : '${holding.ticker} · ${holding.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Money.format(holding.valueCents, currency),
              style: theme.textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ((actual ?? 0) / 100).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(
                'Current $actualLabel · target $targetLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (isOffTarget)
              Text(
                '${drift.abs().toStringAsFixed(1)} pts off',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
