import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/route_names.dart';
import '../../enums/goal_category_enum.dart';
import '../../enums/goal_status_enum.dart';
import '../../models/goal_model.dart';
import '../../services/goal_service.dart';

/// Compact "Goals Progress" widget for the dashboard home page.
///
/// Fetches active goals on its own and renders a small progress bar per
/// goal (nearest deadline first), with a shortcut to the full Goals screen.
class GoalsProgressSection extends StatefulWidget {
  const GoalsProgressSection({super.key});

  @override
  State<GoalsProgressSection> createState() => _GoalsProgressSectionState();
}

class _GoalsProgressSectionState extends State<GoalsProgressSection> {
  late Future<List<GoalModel>> _future;

  static const int _maxVisible = 4;

  @override
  void initState() {
    super.initState();
    _future = GoalService.getAll();
  }

  void refresh() {
    setState(() => _future = GoalService.getAll());
  }

  Color _categoryColor(GoalCategoryEnum category) {
    switch (category) {
      case GoalCategoryEnum.PROFIT:
        return const Color(0xFF22C55E);
      case GoalCategoryEnum.TRADE_QUALITY:
        return const Color(0xFF818CF8);
      case GoalCategoryEnum.DISCIPLINE:
        return const Color(0xFF3B82F6);
      case GoalCategoryEnum.MANUAL:
        return const Color(0xFFF59E0B);
    }
  }

  String _timeLabel(GoalModel goal) {
    if (goal.achieved) return 'Achieved';
    if (goal.daysRemaining <= 0) return 'Ended';
    return '${goal.daysRemaining} day${goal.daysRemaining == 1 ? '' : 's'} left';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.flag_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Goals Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.goNamed(RouteNames.goals),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<GoalModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Failed to load goals',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                );
              }

              final activeGoals =
                  (snapshot.data ?? [])
                      .where((g) => g.status == GoalStatusEnum.ACTIVE)
                      .toList()
                    ..sort(
                      (a, b) => a.daysRemaining.compareTo(b.daysRemaining),
                    );

              if (activeGoals.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        color: Colors.grey.shade300,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No active goals — set one to track your progress',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.goNamed(RouteNames.goals),
                        child: const Text('Set a goal'),
                      ),
                    ],
                  ),
                );
              }

              final visible = activeGoals.take(_maxVisible).toList();

              return Column(
                children: [
                  for (int i = 0; i < visible.length; i++) ...[
                    _buildGoalRow(context, visible[i]),
                    if (i != visible.length - 1) const SizedBox(height: 18),
                  ],
                  if (activeGoals.length > _maxVisible) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.goNamed(RouteNames.goals),
                        child: Text(
                          '+${activeGoals.length - _maxVisible} more goal'
                          '${activeGoals.length - _maxVisible == 1 ? '' : 's'}',
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow(BuildContext context, GoalModel goal) {
    final color = _categoryColor(goal.category);
    final pct = (goal.progressPct / 100).clamp(0, 1).toDouble();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.goNamed(RouteNames.goals),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${goal.progressPct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeLabel(goal),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
