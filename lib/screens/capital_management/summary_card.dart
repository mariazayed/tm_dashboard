import 'package:flutter/material.dart';

import 'stat.dart';
import 'summary_data.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final SummaryData data;

  const SummaryCard({
    required this.title,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final pnlColor = data.pnl >= 0 ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            pnlColor.withOpacity(0.15),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: pnlColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(letterSpacing: 1.2),
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
          Row(
            children: [
              Stat(
                label: 'Profit',
                value: data.profits,
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              Stat(
                label: 'Loss',
                value: data.losses,
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
