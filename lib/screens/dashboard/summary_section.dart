import 'package:flutter/material.dart';

import 'classes/summary_data.dart';
import 'summary_card.dart';

class SummarySection extends StatelessWidget {
  final SummaryData daily;
  final SummaryData weekly;
  final SummaryData monthly;
  final bool wide;

  final VoidCallback? onDailyTap;
  final VoidCallback? onWeeklyTap;
  final VoidCallback? onMonthlyTap;

  const SummarySection({
    super.key,
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.wide,
    this.onDailyTap,
    this.onWeeklyTap,
    this.onMonthlyTap,
  });

  @override
  Widget build(BuildContext context) {
    final children = [
      _buildCard(context, title: "Today", data: daily, onTap: onDailyTap),
      _buildCard(context, title: "This Week", data: weekly, onTap: onWeeklyTap),
      _buildCard(
        context,
        title: "This Month",
        data: monthly,
        onTap: onMonthlyTap,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: wide
          ? Row(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  Expanded(child: children[i]),
                  if (i != children.length - 1) const SizedBox(width: 16),
                ],
              ],
            )
          : Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1) const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required SummaryData data,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SummaryCard(title: title, data: data),
        ),
      ),
    );
  }
}
