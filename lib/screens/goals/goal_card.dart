import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/goal_category_enum.dart';
import '../../enums/goal_status_enum.dart';
import '../../models/goal_model.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<GoalStatusEnum>? onSetStatus;

  const GoalCard({
    super.key,
    required this.goal,
    this.onEdit,
    this.onDelete,
    this.onSetStatus,
  });

  Color get _categoryColor {
    switch (goal.category) {
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

  Color get _statusColor {
    switch (goal.status) {
      case GoalStatusEnum.ACTIVE:
        return const Color(0xFF818CF8);
      case GoalStatusEnum.ACHIEVED:
        return const Color(0xFF22C55E);
      case GoalStatusEnum.FAILED:
        return const Color(0xFFEF4444);
      case GoalStatusEnum.ARCHIVED:
        return Colors.grey;
    }
  }

  String get _valueLabel {
    switch (goal.category) {
      case GoalCategoryEnum.PROFIT:
        final current = goal.currentValue ?? 0;
        final target = goal.targetValue ?? 0;
        return '\$${current.toStringAsFixed(0)} / \$${target.toStringAsFixed(0)}';
      case GoalCategoryEnum.TRADE_QUALITY:
        final current = goal.currentValue ?? 0;
        final target = goal.targetValue ?? 0;
        return '${current.toStringAsFixed(0)}% win rate (target ${target.toStringAsFixed(0)}%)';
      case GoalCategoryEnum.DISCIPLINE:
        final current = goal.currentValue ?? 0;
        return '${current.toStringAsFixed(0)}% of days on plan';
      case GoalCategoryEnum.MANUAL:
        return '${goal.manualProgressPct ?? 0}% complete';
    }
  }

  String get _dateRangeLabel {
    final fmt = DateFormat('MMM d');
    return '${fmt.format(goal.startDate)} – ${fmt.format(goal.endDate)}';
  }

  String get _timeLabel {
    if (goal.status != GoalStatusEnum.ACTIVE) return goal.status.label;
    if (goal.achieved) return 'Achieved';
    if (goal.daysRemaining <= 0) return 'Ended';
    return '${goal.daysRemaining} day${goal.daysRemaining == 1 ? '' : 's'} left';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _categoryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  goal.category.label,
                  style: TextStyle(
                    color: _categoryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (goal.achieved && goal.status == GoalStatusEnum.ACTIVE)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 18),
                ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'achieved':
                      onSetStatus?.call(GoalStatusEnum.ACHIEVED);
                      break;
                    case 'failed':
                      onSetStatus?.call(GoalStatusEnum.FAILED);
                      break;
                    case 'archived':
                      onSetStatus?.call(GoalStatusEnum.ARCHIVED);
                      break;
                    case 'active':
                      onSetStatus?.call(GoalStatusEnum.ACTIVE);
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (goal.status != GoalStatusEnum.ACHIEVED)
                    const PopupMenuItem(value: 'achieved', child: Text('Mark achieved')),
                  if (goal.status != GoalStatusEnum.FAILED)
                    const PopupMenuItem(value: 'failed', child: Text('Mark failed')),
                  if (goal.status != GoalStatusEnum.ARCHIVED)
                    const PopupMenuItem(value: 'archived', child: Text('Archive')),
                  if (goal.status != GoalStatusEnum.ACTIVE)
                    const PopupMenuItem(value: 'active', child: Text('Reactivate')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            goal.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (goal.progressPct / 100).clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: Colors.grey.shade100,
              color: _categoryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _valueLabel,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _dateRangeLabel,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _timeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
