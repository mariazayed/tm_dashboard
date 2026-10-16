import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/invest/contribution_model.dart';
import '../../models/invest/money.dart';

/// A compact activity view for the latest investment contributions.
class RecentContributionsCard extends StatelessWidget {
  const RecentContributionsCard({
    super.key,
    required this.contributions,
    required this.currency,
    required this.onViewAll,
  });

  final List<ContributionModel> contributions;
  final String currency;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = [...contributions]
      ..sort((a, b) => b.contributedOn.compareTo(a.contributedOn));
    final visible = latest.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent contributions',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(onPressed: onViewAll, child: const Text('View all')),
              ],
            ),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Your investment contributions will appear here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.south_west_rounded,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(visible[i].ticker ?? 'Investment contribution'),
                  subtitle: Text(
                    '${DateFormat.yMMMd().format(visible[i].contributedOn)}'
                    ' · cash left ${Money.format(visible[i].cashLeftCents, currency)}',
                  ),
                  trailing: Text(
                    Money.format(
                      visible[i].amountCents + visible[i].feeCents,
                      currency,
                    ),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
