import 'package:flutter/material.dart';

import '../../models/invest/contribution_status_model.dart';
import '../../theme/app_semantic_colors.dart';

/// "This month" headline plus a strip of month chips and streak numbers.
class ContributionStatusCard extends StatelessWidget {
  const ContributionStatusCard({super.key, required this.status});

  final ContributionStatusModel status;

  static String headline(ContributionStatusModel s) {
    final current = s.current;
    if (current == null) return 'Your plan has not started yet';
    switch (current.state) {
      case MonthState.done:
        return 'This month: done';
      case MonthState.pending:
        final days = s.daysUntilDue ?? 0;
        if (days == 0) return 'This month: due today';
        return 'This month: due in $days ${days == 1 ? 'day' : 'days'}';
      case MonthState.overdue:
        final late = -(s.daysUntilDue ?? 0);
        return 'This month: overdue by $late ${late == 1 ? 'day' : 'days'}';
      case MonthState.missed:
        return 'This month: missed';
    }
  }

  static Color colorFor(BuildContext context, MonthState state) {
    final colors = context.semanticColors;
    switch (state) {
      case MonthState.done:
        return colors.profit;
      case MonthState.missed:
        return colors.loss;
      case MonthState.overdue:
        return colors.warning;
      case MonthState.pending:
        return colors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = status.current;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headline(status),
              key: const Key('status-headline'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: current == null
                    ? null
                    : colorFor(context, current.state),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _Stat('Streak', '${status.currentStreak}'),
                _Stat('Best streak', '${status.longestStreak}'),
                _Stat('Missed months', '${status.missedCount}'),
              ],
            ),
            if (status.months.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in status.months)
                    Tooltip(
                      message: '${m.month}: ${m.state.name}',
                      child: Chip(
                        key: Key('month-${m.month}'),
                        label: Text(m.month.substring(2)),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: colorFor(context, m.state)),
                        backgroundColor: colorFor(
                          context,
                          m.state,
                        ).withValues(alpha: 0.15),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.headlineSmall),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
