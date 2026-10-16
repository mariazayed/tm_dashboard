import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/route_names.dart';
import '../../enums/plan_item_status_enum.dart';
import '../../models/planner_models.dart';
import '../../services/api_client.dart';
import '../../services/planner_service.dart';
import '../../theme/app_theme.dart';

/// Compact weekly planning snapshot for the investing overview.
class InvestingPlannerPreview extends StatefulWidget {
  const InvestingPlannerPreview({super.key});

  @override
  State<InvestingPlannerPreview> createState() =>
      _InvestingPlannerPreviewState();
}

class _InvestingPlannerPreviewState extends State<InvestingPlannerPreview> {
  late Future<PlannerOverviewModel> _future = PlannerService.getOverview();

  void _openPlanner() => context.goNamed(RouteNames.planner);

  void _refresh() {
    setState(
      () => _future = ApiClient.shared.refresh(PlannerService.getOverview),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('This week', style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  tooltip: 'Refresh weekly plan',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh, size: 19),
                ),
                TextButton(
                  onPressed: _openPlanner,
                  child: const Text('Open planner'),
                ),
              ],
            ),
            FutureBuilder<PlannerOverviewModel>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return _message(
                    context,
                    icon: Icons.event_note_outlined,
                    title: 'Planner preview unavailable',
                    subtitle: 'Open Planner to organize your investing week.',
                    action: 'Open Planner',
                    onAction: _openPlanner,
                  );
                }
                final week = snapshot.data!.currentWeek;
                if (week.tasks.isEmpty) {
                  return _message(
                    context,
                    icon: Icons.event_available_outlined,
                    title: 'Make time for your investing routine',
                    subtitle:
                        'Plan research, portfolio reviews, learning, or journaling for this week.',
                    action: 'Plan this week',
                    onAction: _openPlanner,
                  );
                }
                final progress = (week.evaluation.completionPct / 100).clamp(
                  0.0,
                  1.0,
                );
                final tasks = week.tasks.take(3).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${week.tasks.length} planned task${week.tasks.length == 1 ? '' : 's'} · '
                      '${week.plannedHours.toStringAsFixed(week.plannedHours % 1 == 0 ? 0 : 1)} hours scheduled',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${week.evaluation.doneCount} of ${week.tasks.length} tasks completed',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final task in tasks)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              task.status == PlanItemStatusEnum.DONE
                                  ? Icons.check_circle_outline
                                  : Icons.radio_button_unchecked,
                              size: 17,
                              color: task.status == PlanItemStatusEnum.DONE
                                  ? context.semanticColors.profit
                                  : colors.outline,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${task.estimatedHours.toStringAsFixed(task.estimatedHours % 1 == 0 ? 0 : 1)}h',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (week.tasks.length > tasks.length)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _openPlanner,
                          child: Text(
                            'View ${week.tasks.length - tasks.length} more',
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: onAction, child: Text(action)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
