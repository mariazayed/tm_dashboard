import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/goal_category_enum.dart';
import '../../enums/goal_status_enum.dart';
import '../../models/goal_model.dart';
import '../../theme/app_theme.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<GoalStatusEnum>? onSetStatus;
  // True while a delete or status-change request for this goal is in
  // flight (tracked by the parent GoalsScreen, one goal at a time can be
  // busy without blocking the rest of the grid). Swaps the "..." menu for
  // a small spinner and dims the card so there's visible feedback while
  // waiting on the server, instead of the menu just silently doing nothing
  // if tapped again.
  final bool busy;

  const GoalCard({
    super.key,
    required this.goal,
    this.onEdit,
    this.onDelete,
    this.onSetStatus,
    this.busy = false,
  });

  Color _categoryColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;

    switch (goal.category) {
      case GoalCategoryEnum.PROFIT:
        return semantic.profit;
      case GoalCategoryEnum.TRADE_QUALITY:
        return colorScheme.primary;
      case GoalCategoryEnum.DISCIPLINE:
        return semantic.info;
      case GoalCategoryEnum.MANUAL:
        return semantic.warning;
    }
  }

  Color _statusColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;

    switch (goal.status) {
      case GoalStatusEnum.ACTIVE:
        return colorScheme.primary;
      case GoalStatusEnum.ACHIEVED:
        return semantic.profit;
      case GoalStatusEnum.FAILED:
        return semantic.loss;
      case GoalStatusEnum.ARCHIVED:
        return colorScheme.onSurfaceVariant;
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
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final categoryColor = _categoryColor(context);
    final statusColor = _statusColor(context);

    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
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
                  color: categoryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  goal.category.label,
                  style: TextStyle(
                    color: categoryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              if (goal.achieved && goal.status == GoalStatusEnum.ACTIVE)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.emoji_events, color: semantic.warning, size: 18),
                ),
              busy
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
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
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (goal.progressPct / 100).clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHigh,
              color: categoryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _valueLabel,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _dateRangeLabel,
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _timeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
