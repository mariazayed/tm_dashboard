import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/plan_item_status_enum.dart';
import '../../models/planner_models.dart';
import '../../services/planner_service.dart';
import '../../theme/app_theme.dart';
import 'planner_style.dart';
import 'sheets/evaluation_sheet.dart';
import 'sheets/plan_item_sheet.dart';
import 'widgets/planner_widgets.dart';

/// Monthly plan: capacity from the calendar, objectives (with progress
/// rolled up from linked weekly tasks), per-area budget, a strip of the
/// month's weeks, and evaluation.
class MonthView extends StatefulWidget {
  final DateTime month; // first day of the month
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onOpenWeek;
  final VoidCallback onGoToSetup;

  const MonthView({
    super.key,
    required this.month,
    required this.onMonthChanged,
    required this.onOpenWeek,
    required this.onGoToSetup,
  });

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  MonthPlanModel? _plan;
  List<FocusAreaModel> _areas = [];
  Object? _error;
  bool _loading = false;
  PlannerMode _mode = PlannerMode.plan;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _mode = _defaultMode(widget.month);
    _load();
  }

  @override
  void didUpdateWidget(covariant MonthView old) {
    super.didUpdateWidget(old);
    if (old.month != widget.month) {
      _mode = _defaultMode(widget.month);
      _plan = null;
      _load();
    }
  }

  PlannerMode _defaultMode(DateTime month) {
    final now = DateTime.now();
    return month.isBefore(DateTime(now.year, now.month)) ? PlannerMode.evaluate : PlannerMode.plan;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        PlannerService.getMonth(widget.month.year, widget.month.month),
        PlannerService.getFocusAreas(),
      ]);
      if (!mounted) return;
      setState(() {
        _plan = results[0] as MonthPlanModel;
        _areas = results[1] as List<FocusAreaModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  List<FocusAreaModel> get _activeAreas => _areas.where((a) => !a.archived).toList();

  String get _monthLabel => DateFormat('MMMM yyyy').format(widget.month);

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------------ actions

  Future<void> _openObjectiveSheet({MonthlyObjectiveModel? objective}) async {
    final areas = _activeAreas;
    if (objective != null && !areas.any((a) => a.id == objective.focusArea.id)) {
      areas.add(objective.focusArea);
    }
    final saved = await showPlannerSheet<bool>(
      context,
      PlanItemSheet(
        isMonthly: true,
        periodLabel: _monthLabel,
        areas: areas,
        period: _plan!,
        editingId: objective?.id,
        initialTitle: objective?.title,
        initialAreaId: objective?.focusArea.id,
        initialHours: objective?.estimatedHours,
        initialNotes: objective?.notes,
        onSubmit: (d) {
          final data = <String, dynamic>{
            'planYear': widget.month.year,
            'planMonth': widget.month.month,
            'title': d.title,
            'focusAreaId': d.focusAreaId,
            'estimatedHours': d.estimatedHours,
            'notes': d.notes,
          };
          if (objective == null) return PlannerService.createObjective(data);
          return PlannerService.updateObjective(objective.id, data);
        },
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _openEvaluation(MonthlyObjectiveModel o) async {
    final saved = await showPlannerSheet<bool>(
      context,
      EvaluationSheet(
        title: o.title,
        focusArea: o.focusArea,
        estimatedHours: o.estimatedHours,
        status: o.status,
        score: o.score,
        actualHours: o.actualHours,
        evaluationNotes: o.evaluationNotes,
        suggestedActualHours: o.linkedCreditedHours,
        onSubmit: (e) => PlannerService.evaluateObjective(o.id, e),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _quickStatus(MonthlyObjectiveModel o, PlanItemStatusEnum status) async {
    setState(() => _busy.add(o.id));
    try {
      await PlannerService.evaluateObjective(
        o.id,
        PlannerEvaluation(
          status: status,
          score: o.score,
          actualHours: o.actualHours,
          evaluationNotes: o.evaluationNotes,
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _busy.remove(o.id));
    }
  }

  Future<void> _deleteObjective(MonthlyObjectiveModel o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete objective'),
        content: Text(
          'Delete "${o.title}"?'
          '${o.linkedTaskCount > 0 ? '\n\n${o.linkedTaskCount} linked weekly task${o.linkedTaskCount == 1 ? '' : 's'} will be kept but unlinked.' : ''}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy.add(o.id));
    try {
      await PlannerService.deleteObjective(o.id);
      await _load();
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _busy.remove(o.id));
    }
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final now = DateTime.now();
    final isCurrent = widget.month.year == now.year && widget.month.month == now.month;

    return Column(
      children: [
        SizedBox(height: 3, child: _loading && plan != null ? const LinearProgressIndicator() : null),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              children: [
                PeriodNavigator(
                  title: _monthLabel,
                  subtitle: isCurrent ? 'This month' : 'Monthly plan',
                  onPrevious: () => widget.onMonthChanged(DateTime(widget.month.year, widget.month.month - 1)),
                  onNext: () => widget.onMonthChanged(DateTime(widget.month.year, widget.month.month + 1)),
                  onCurrent: isCurrent ? null : () => widget.onMonthChanged(DateTime(now.year, now.month)),
                  currentLabel: 'This month',
                ),
                const SizedBox(height: 20),
                if (plan == null && _error == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (plan == null)
                  PlannerEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Couldn\'t load this month',
                    message: '$_error',
                    actionLabel: 'Retry',
                    onAction: _load,
                  )
                else
                  _buildBody(plan),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(MonthPlanModel plan) {
    final evaluating = _mode == PlannerMode.evaluate;

    final toolbar = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PlannerModeToggle(mode: _mode, onChanged: (m) => setState(() => _mode = m)),
        if (!evaluating && _activeAreas.isNotEmpty)
          FilledButton.icon(
            onPressed: () => _openObjectiveSheet(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add objective'),
          ),
      ],
    );

    final capacity = CapacityCard(
      period: plan,
      capacityLabel: 'Capacity',
      action: Text(
        '${PlannerStyle.hours(plan.baseHours)} from ${plan.workingDays} working days'
        '${plan.extraHours > 0 ? ' + ${PlannerStyle.hours(plan.extraHours)} extra (added per week)' : ''}',
        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
    final allocation = AllocationPanel(areas: plan.areas, showActual: evaluating);
    final summary = EvaluationSummaryCard(summary: plan.evaluation, title: 'Month evaluation');
    final weeks = _WeeksStrip(weeks: plan.weeks, onOpenWeek: widget.onOpenWeek);
    final objectives = _buildObjectives(plan);

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= 1050) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              toolbar,
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [objectives, const SizedBox(height: 20), weeks],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        capacity,
                        const SizedBox(height: 20),
                        if (evaluating) ...[summary, const SizedBox(height: 20)],
                        allocation,
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            capacity,
            const SizedBox(height: 20),
            toolbar,
            const SizedBox(height: 20),
            if (evaluating) ...[summary, const SizedBox(height: 20)],
            objectives,
            const SizedBox(height: 20),
            weeks,
            const SizedBox(height: 20),
            allocation,
          ],
        );
      },
    );
  }

  Widget _buildObjectives(MonthPlanModel plan) {
    if (_areas.isEmpty) {
      return PlannerPanel(
        child: PlannerEmptyState(
          icon: Icons.category_outlined,
          title: 'Set up your Focus Areas first',
          message: 'Objectives belong to a Focus Area, which caps how much of the month it can take.',
          actionLabel: 'Create Focus Areas',
          onAction: widget.onGoToSetup,
        ),
      );
    }
    if (plan.objectives.isEmpty) {
      return PlannerPanel(
        child: PlannerEmptyState(
          icon: Icons.track_changes_outlined,
          title: 'No objectives for $_monthLabel',
          message: 'Set a few monthly objectives, then link weekly tasks to them to track progress automatically.',
          actionLabel: 'Add objective',
          onAction: _activeAreas.isEmpty ? null : () => _openObjectiveSheet(),
        ),
      );
    }

    return Column(
      children: plan.objectives
          .map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ObjectiveCard(
                  objective: o,
                  mode: _mode,
                  busy: _busy.contains(o.id),
                  onTap: () => _mode == PlannerMode.evaluate ? _openEvaluation(o) : _openObjectiveSheet(objective: o),
                  onEdit: () => _openObjectiveSheet(objective: o),
                  onEvaluate: () => _openEvaluation(o),
                  onDelete: () => _deleteObjective(o),
                  onQuickStatus: (s) => _quickStatus(o, s),
                ),
              ))
          .toList(),
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  final MonthlyObjectiveModel objective;
  final PlannerMode mode;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onEvaluate;
  final VoidCallback onDelete;
  final ValueChanged<PlanItemStatusEnum> onQuickStatus;

  const _ObjectiveCard({
    required this.objective,
    required this.mode,
    required this.busy,
    required this.onTap,
    required this.onEdit,
    required this.onEvaluate,
    required this.onDelete,
    required this.onQuickStatus,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final o = objective;
    final color = PlannerStyle.colorFromHex(o.focusArea.color);
    final evaluating = mode == PlannerMode.evaluate;
    final progressColor = o.progressPct >= 100 ? semantic.profit : color;

    return Opacity(
      opacity: busy ? 0.55 : 1,
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: busy ? null : onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AreaIconBadge(area: o.focusArea, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              AreaTag(area: o.focusArea, dense: true),
                              Text(
                                '${PlannerStyle.hours(o.estimatedHours)} planned'
                                '${o.actualHours != null ? ' · ${PlannerStyle.hours(o.actualHours!)} actual' : ''}',
                                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                              ),
                              if (o.status.isEvaluated) StatusPill(status: o.status),
                              if (o.score != null) ScoreStars(score: o.score, size: 14),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (evaluating)
                      QuickStatusButtons(status: o.status, busy: busy, onChanged: onQuickStatus)
                    else
                      PopupMenuButton<String>(
                        enabled: !busy,
                        icon: const Icon(Icons.more_vert),
                        onSelected: (v) {
                          switch (v) {
                            case 'edit':
                              onEdit();
                            case 'evaluate':
                              onEvaluate();
                            case 'delete':
                              onDelete();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'))),
                          PopupMenuItem(value: 'evaluate', child: ListTile(leading: Icon(Icons.rate_review_outlined), title: Text('Evaluate'))),
                          PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete'))),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: o.progressPct / 100),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 8,
                              color: progressColor,
                              backgroundColor: cs.surfaceContainerHighest,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        PlannerStyle.pct(o.progressPct),
                        style: TextStyle(fontWeight: FontWeight.w800, color: progressColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  o.linkedTaskCount == 0
                      ? 'No weekly tasks linked yet'
                      : '${o.linkedDoneCount}/${o.linkedTaskCount} linked tasks done · '
                          '${PlannerStyle.hours(o.linkedCreditedHours)} of ${PlannerStyle.hours(o.estimatedHours)} credited',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                if (evaluating && (o.evaluationNotes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '“${o.evaluationNotes!}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: cs.onSurfaceVariant),
                  ),
                ] else if ((o.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    o.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tile per week starting in this month; tap to open that week.
class _WeeksStrip extends StatelessWidget {
  final List<WeekSnapshotModel> weeks;
  final ValueChanged<DateTime> onOpenWeek;

  const _WeeksStrip({required this.weeks, required this.onOpenWeek});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final thisMonday = mondayOf(DateTime.now());

    return PlannerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(title: 'Weeks this month', icon: Icons.view_week_outlined),
          LayoutBuilder(
            builder: (context, c) {
              final cols = (c.maxWidth / 170).floor().clamp(1, 5).toInt();
              final width = (c.maxWidth - (cols - 1) * 12) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: weeks.map((w) {
                  final isNow = w.weekStart == thisMonday;
                  final load = w.capacityHours > 0 ? w.plannedHours / w.capacityHours : 0.0;
                  final over = w.plannedHours > w.capacityHours + 1e-9;
                  return SizedBox(
                    width: width,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onOpenWeek(w.weekStart),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isNow ? cs.primary.withValues(alpha: 0.07) : null,
                          border: Border.all(color: isNow ? cs.primary : cs.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'W${PlannerStyle.isoWeek(w.weekStart)}',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: isNow ? cs.primary : null),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_forward, size: 14, color: cs.onSurfaceVariant),
                              ],
                            ),
                            Text(
                              DateFormat('MMM d').format(w.weekStart),
                              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: load.clamp(0, 1).toDouble(),
                                minHeight: 6,
                                color: over ? semantic.loss : cs.primary,
                                backgroundColor: cs.surfaceContainerHighest,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${PlannerStyle.hours(w.plannedHours)} / ${PlannerStyle.hours(w.capacityHours)}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: over ? semantic.loss : null),
                            ),
                            Text(
                              w.taskCount == 0 ? 'No tasks' : '${w.doneCount}/${w.taskCount} done · ${PlannerStyle.pct(w.completionPct)}',
                              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
