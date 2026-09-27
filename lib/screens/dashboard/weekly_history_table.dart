import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import 'classes/weekly_breakdown.dart';

class WeeklyHistoryTable extends StatelessWidget {
  final List<WeeklyBreakdown> weeks;

  const WeeklyHistoryTable({super.key, required this.weeks});

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No weekly data")),
      );
    }

    final formatter = DateFormat('MMM d');
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;

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
          Text(
            "Weekly Performance",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 20),

          /// Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(child: Text("Week")),
              Expanded(child: Text("Profit")),
              Expanded(child: Text("Loss")),
              Expanded(child: Text("Net")),
            ],
          ),

          const Divider(height: 28),

          ...weeks.map((week) {
            final weekEnd = week.weekStart.add(const Duration(days: 6));

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${formatter.format(week.weekStart)} - ${formatter.format(weekEnd)}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      week.profit.toStringAsFixed(2),
                      style: TextStyle(
                        color: semantic.profit,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      week.loss.toStringAsFixed(2),
                      style: TextStyle(
                        color: semantic.loss,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      week.net.toStringAsFixed(2),
                      style: TextStyle(
                        color: week.net >= 0 ? semantic.profit : semantic.loss,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
