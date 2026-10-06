import 'package:flutter/material.dart';

/// Your written strategy, always one tap away on the dashboard. Open by default:
/// the point is to see it before you do anything hasty.
class RulesCard extends StatelessWidget {
  const RulesCard({super.key, required this.rules, required this.onEdit});

  final List<String> rules;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        key: const Key('rules-card'),
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text('My rules', style: theme.textTheme.titleMedium),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rules.isEmpty)
            Text(
              'You have not written any rules yet. A few lines you can read '
              'when markets get loud.',
              key: const Key('rules-empty'),
              style: theme.textTheme.bodyMedium,
            ),
          for (var i = 0; i < rules.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text('${i + 1}.', style: theme.textTheme.bodyMedium),
                  ),
                  Expanded(
                    child: Text(rules[i], style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('edit-rules'),
              onPressed: onEdit,
              child: Text(rules.isEmpty ? 'Add rules' : 'Edit rules'),
            ),
          ),
        ],
      ),
    );
  }
}
