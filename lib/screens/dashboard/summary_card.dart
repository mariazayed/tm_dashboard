import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'capital_stat.dart';
import 'classes/summary_data.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final SummaryData data;

  const SummaryCard({super.key, required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final pnlColor = data.pnl >= 0 ? semantic.profit : semantic.loss;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),

          /// PnL
          Text(
            data.pnl.toStringAsFixed(2),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: pnlColor,
            ),
          ),
          const SizedBox(height: 8),

          /// Breakdown
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              CapitalStat(
                label: 'Profit',
                value: data.profits,
                color: semantic.profit,
              ),
              CapitalStat(
                label: 'Loss',
                value: data.losses,
                color: semantic.loss,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
