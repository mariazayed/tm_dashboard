import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
          ),
        ],
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
                        color: Colors.green.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      week.loss.toStringAsFixed(2),
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      week.net.toStringAsFixed(2),
                      style: TextStyle(
                        color: week.net >= 0
                            ? Colors.green.shade600
                            : Colors.red.shade600,
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
