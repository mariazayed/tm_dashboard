import 'package:flutter/material.dart';

import '../../enums/plan_item_status_enum.dart';
import '../../models/planner_models.dart';
import '../../services/planner_service.dart';
import '../../theme/app_theme.dart';
import 'planner_style.dart';
import 'sheets/evaluation_sheet.dart';
import 'sheets/extra_hours_sheet.dart';
import 'sheets/log_time_sheet.dart';
import 'sheets/plan_item_sheet.dart';
import 'widgets/planner_widgets.dart';

/// Weekly plan: capacity, tasks grouped by Focus Area, per-area budget,
/// and (in Evaluate mode) one-tap outcomes + full evaluation sheet.
class WeekView extends StatefulWidget {
  final DateTime weekStart;
  final ValueChanged<DateTime> onWeekChanged;
  final VoidCallback onGoToSetup;

  const WeekView({
    super.key,
    required this.weekStart,
    required this.onWeekChanged,
    required this.onGoToSetup,
  });

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  WeekPlanModel? _plan;
  List<FocusAreaModel> _areas = [];
  Object? _error;
  bool _loading = false;
  PlannerMode _mode = PlannerMode.plan;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _mode = _defaultMode(widget.weekStart);
    _load();
  }

  @override
  void didUpdateWidget(covariant WeekView old) {
    super.didUpdateWidget(old);
    if (old.weekStart != widget.weekStart) {
      _mode = _defaultMode(widget.weekStart);
      _plan = null;
      _load();
    }
  }

  /// Past weeks open in Evaluate mode, current/future weeks in Plan mode.
  PlannerMode _defaultMode(DateTime monday) =>
      monday.isBefore(mondayOf(DateTime.now())) ? PlannerMode.evaluate : PlannerMode.plan;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        PlannerService.getWeek(widget.weekStart),
        PlannerService.getFocusAreas(),
      ]);
      if (!mounted) return;
      setState(() {
        _plan = results[0] as WeekPlanModel;
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

  String get _weekLabel =>
      'Week ${PlannerStyle.isoWeek(widget.weekStart)} · ${PlannerStyle.weekRange(widget.weekStart)}';

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------------ actions

  Future<void> _openTaskSheet({WeeklyTaskModel? task}) async {
    if (task != null && task.isExtra) return _openExtraHours(existing: task);
    final plan = _plan!;
    final areas = _activeAreas;
    // Keep an archived area selectable when editing a task that uses it.
    if (task != null && !areas.any((a) => a.id == task.focusArea.id)) {
      areas.add(task.focusArea);
    }
    final saved = await showPlannerSheet<bool>(
      context,
      PlanItemSheet(
        isMonthly: false,
        periodLabel: _weekLabel,
        areas: areas,
        period: plan,
        objectives: plan.objectives,
        editingId: task?.id,
        initialTitle: task?.title,
        initialAreaId: task?.focusArea.id,
        initialHours: task?.estimatedHours,
        initialNotes: task?.notes,
        initialObjectiveId: task?.monthlyObjectiveId,
        showActualHours: true,
        initialActualHours: task?.actualHours,
        onSubmit: (d) {
          final data = <String, dynamic>{
            'weekStart': plannerDateFormat.format(widget.weekStart),
            'title': d.title,
            'focusAreaId': d.focusAreaId,
            'estimatedHours': d.estimatedHours,
            'notes': d.notes,
            'monthlyObjectiveId': d.monthlyObjectiveId,
            if (d.actualHours != null) 'actualHours': d.actualHours,
          };
          if (task == null) return PlannerService.createTask(data);
          if (d.actualHours == null && task.actualHours != null) data['clearActualHours'] = true;
          if (d.monthlyObjectiveId == null) data['unlinkObjective'] = true;
          return PlannerService.updateTask(task.id, data);
        },
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _openEvaluation(WeeklyTaskModel task) async {
    final saved = await showPlannerSheet<bool>(
      context,
      EvaluationSheet(
        title: task.title,
        focusArea: task.focusArea,
        estimatedHours: task.estimatedHours,
        status: task.status,
        score: task.score,
        actualHours: task.actualHours,
        evaluationNotes: task.evaluationNotes,
        onSubmit: (e) => PlannerService.evaluateTask(task.id, e),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _openLogTime(WeeklyTaskModel task) async {
    final saved = await showPlannerSheet<bool>(
      context,
      LogTimeSheet(
        task: task,
        onSubmit: (hours) => PlannerService.updateTask(
          task.id,
          hours == null ? {'clearActualHours': true} : {'actualHours': hours},
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _quickStatus(WeeklyTaskModel task, PlanItemStatusEnum status) async {
    setState(() => _busy.add(task.id));
    try {
      await PlannerService.evaluateTask(
        task.id,
        PlannerEvaluation(
          status: status,
          score: task.score,
          actualHours: task.actualHours,
          evaluationNotes: task.evaluationNotes,
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _busy.remove(task.id));
    }
  }

  Future<void> _moveToNextWeek(WeeklyTaskModel task) async {
    setState(() => _busy.add(task.id));
    try {
      final next = widget.weekStart.add(const Duration(days: 7));
      await PlannerService.updateTask(task.id, {'weekStart': plannerDateFormat.format(next)});
      await _load();
      if (mounted) _snack('Moved "${task.title}" to next week');
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _busy.remove(task.id));
    }
  }

  Future<void> _deleteTask(WeeklyTaskModel task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(task.isExtra ? 'Remove extra hours' : 'Delete task'),
        content: Text(task.isExtra
            ? 'Remove "${task.title}" (+${PlannerStyle.hours(task.estimatedHours)})? The week\'s capacity drops by the same amount.'
            : 'Delete "${task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy.add(task.id));
    try {
      await PlannerService.deleteTask(task.id);
      await _load();
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _busy.remove(task.id));
    }
  }

  /// Add (or edit) extra working hours -- saved as an extra task in the
  /// chosen Focus Area's list.
  Future<void> _openExtraHours({WeeklyTaskModel? existing}) async {
    final saved = await showPlannerSheet<bool>(
      context,
      ExtraHoursSheet(
        weekLabel: _weekLabel,
        weekStart: widget.weekStart,
        plan: _plan!,
        areas: _areas,
        existing: existing,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _carryOver() async {
    final before = _plan?.tasks.length ?? 0;
    setState(() => _loading = true);
    try {
      final plan = await PlannerService.carryOver(widget.weekStart);
      if (!mounted) return;
      final added = plan.tasks.length - before;
      setState(() {
        _plan = plan;
        _loading = false;
      });
      _snack(added > 0
          ? 'Carried over $added unfinished task${added == 1 ? '' : 's'} from last week'
          : 'Nothing to carry over — last week had no unfinished tasks');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('$e');
    }
  }

  // ------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final isCurrent = widget.weekStart == mondayOf(DateTime.now());

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
                  title: 'Week ${PlannerStyle.isoWeek(widget.weekStart)}',
                  subtitle: PlannerStyle.weekRange(widget.weekStart) + (isCurrent ? '  ·  this week' : ''),
                  onPrevious: () => widget.onWeekChanged(widget.weekStart.subtract(const Duration(days: 7))),
                  onNext: () => widget.onWeekChanged(widget.weekStart.add(const Duration(days: 7))),
                  onCurrent: isCurrent ? null : () => widget.onWeekChanged(mondayOf(DateTime.now())),
                  currentLabel: 'This week',
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
                    title: 'Couldn\'t load this week',
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

  Widget _buildBody(WeekPlanModel plan) {
    final evaluating = _mode == PlannerMode.evaluate;

    final toolbar = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PlannerModeToggle(mode: _mode, onChanged: (m) => setState(() => _mode = m)),
        if (!evaluating) ...[
          OutlinedButton.icon(
            onPressed: _loading ? null : _carryOver,
            icon: const Icon(Icons.redo_rounded, size: 18),
            label: const Text('Carry over unfinished'),
          ),
          if (_activeAreas.isNotEmpty) ...[
            OutlinedButton.icon(
              onPressed: () => _openExtraHours(),
              icon: const Icon(Icons.more_time_outlined, size: 18),
              label: const Text('Add extra hours'),
            ),
            FilledButton.icon(
              onPressed: () => _openTaskSheet(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add task'),
            ),
          ],
        ],
      ],
    );

    final capacity = CapacityCard(
      period: plan,
      capacityLabel: 'Capacity',
      action: Row(
        children: [
          Expanded(
            child: Text(
              plan.extraHours > 0
                  ? '${PlannerStyle.hours(plan.baseHours)} regular + ${PlannerStyle.hours(plan.extraHours)} extra (in the task list)'
                  : '${PlannerStyle.hours(plan.baseHours)} from your working hours',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          if (_activeAreas.isNotEmpty)
            TextButton.icon(
              onPressed: () => _openExtraHours(),
              icon: const Icon(Icons.more_time_outlined, size: 18),
              label: const Text('Add extra hours'),
            ),
        ],
      ),
    );

    final allocation = AllocationPanel(areas: plan.areas, showActual: evaluating, regularHours: plan.baseHours);
    final summary = EvaluationSummaryCard(summary: plan.evaluation, title: 'Week evaluation');
    final tasks = _buildTasks(plan);

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
                  Expanded(flex: 3, child: tasks),
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
            tasks,
            const SizedBox(height: 20),
            allocation,
          ],
        );
      },
    );
  }

  Widget _buildTasks(WeekPlanModel plan) {
    if (_areas.isEmpty) {
      return PlannerPanel(
        child: PlannerEmptyState(
          icon: Icons.category_outlined,
          title: 'Set up your Focus Areas first',
          message: 'Focus Areas group your tasks (Backtesting, Journaling, Learning…) and cap how much of the week each one can take.',
          actionLabel: 'Create Focus Areas',
          onAction: widget.onGoToSetup,
        ),
      );
    }
    if (plan.tasks.isEmpty) {
      return PlannerPanel(
        child: PlannerEmptyState(
          icon: Icons.event_note_outlined,
          title: 'Nothing planned for this week yet',
          message: 'Add the tasks you want to get done, or carry over what was left from last week.',
          actionLabel: 'Add task',
          onAction: _activeAreas.isEmpty ? null : () => _openTaskSheet(),
        ),
      );
    }

    // Group by Focus Area, in the allocation order the server returned.
    final order = plan.areas.map((a) => a.focusArea.id).toList();
    final groups = <int, List<WeeklyTaskModel>>{};
    for (final t in plan.tasks) {
      groups.putIfAbsent(t.focusArea.id, () => []).add(t);
    }
    final ids = groups.keys.toList()
      ..sort((a, b) {
        final ia = order.indexOf(a), ib = order.indexOf(b);
        return (ia < 0 ? 999 : ia).compareTo(ib < 0 ? 999 : ib);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ids.map((id) {
        final items = groups[id]!;
        final area = items.first.focusArea;
        final alloc = plan.areas.where((a) => a.focusArea.id == id).firstOrNull;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _AreaGroup(
            area: area,
            allocation: alloc,
            count: items.length,
            children: items
                .map((t) => _TaskCard(
                      task: t,
                      mode: _mode,
                      busy: _busy.contains(t.id),
                      onTap: () => _mode == PlannerMode.evaluate ? _openEvaluation(t) : _openTaskSheet(task: t),
                      onEdit: () => _openTaskSheet(task: t),
                      onEvaluate: () => _openEvaluation(t),
                      onDelete: () => _deleteTask(t),
                      onMoveNext: () => _moveToNextWeek(t),
                      onLogTime: () => _openLogTime(t),
                      onQuickStatus: (s) => _quickStatus(t, s),
                    ))
                .toList(),
          ),
        );
      }).toList(),
    );
  }
}

/// Header + cards for one Focus Area inside a period.
class _AreaGroup extends StatelessWidget {
  final FocusAreaModel area;
  final AreaAllocationModel? allocation;
  final int count;
  final List<Widget> children;

  const _AreaGroup({
    required this.area,
    required this.allocation,
    required this.count,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final a = allocation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Row(
            children: [
              AreaTag(area: area),
              const SizedBox(width: 10),
              Text('$count', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (a != null) ...[
                if (a.overLimit) ...[
                  Icon(Icons.warning_amber_rounded, size: 16, color: semantic.loss),
                  const SizedBox(width: 4),
                ],
                Text(
                  '${PlannerStyle.hours(a.plannedHours)} of ${PlannerStyle.hours(a.allowedHours)} budget',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: a.overLimit ? semantic.loss : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ...children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final WeeklyTaskModel task;
  final PlannerMode mode;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onEvaluate;
  final VoidCallback onDelete;
  final VoidCallback onMoveNext;
  final VoidCallback onLogTime;
  final ValueChanged<PlanItemStatusEnum> onQuickStatus;

  const _TaskCard({
    required this.task,
    required this.mode,
    required this.busy,
    required this.onTap,
    required this.onEdit,
    required this.onEvaluate,
    required this.onDelete,
    required this.onMoveNext,
    required this.onLogTime,
    required this.onQuickStatus,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = PlannerStyle.colorFromHex(task.focusArea.color);
    final evaluating = mode == PlannerMode.evaluate;
    final done = task.status == PlanItemStatusEnum.DONE;

    return Opacity(
      opacity: busy ? 0.55 : 1,
      child: Material(
        // Extra-hours items get a faint tint of their area's color so they
        // read as "extra time" at a glance, while living in the same list.
        color: task.isExtra ? Color.alphaBlend(color.withValues(alpha: 0.06), cs.surface) : cs.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: busy ? null : onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: task.isExtra ? color.withValues(alpha: 0.45) : cs.outlineVariant),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              decoration: done && evaluating ? TextDecoration.lineThrough : null,
                              color: done && evaluating ? cs.onSurfaceVariant : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (task.isExtra) _ExtraBadge(hours: task.estimatedHours, color: color),
                              if (!task.isExtra)
                                _MetaChip(icon: Icons.schedule_outlined, label: '${PlannerStyle.hours(task.estimatedHours)} est.'),
                              if (task.monthlyObjectiveTitle != null)
                                _MetaChip(icon: Icons.track_changes_outlined, label: task.monthlyObjectiveTitle!),
                              if (task.status.isEvaluated) StatusPill(status: task.status),
                              if (task.score != null) ScoreStars(score: task.score, size: 14),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _TimeRow(task: task, onLog: busy ? null : onLogTime),
                          if ((task.notes ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              task.notes!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                            ),
                          ],
                          if (evaluating && (task.evaluationNotes ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              '“${task.evaluationNotes!}”',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: cs.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: evaluating
                          ? QuickStatusButtons(status: task.status, busy: busy, onChanged: onQuickStatus)
                          : PopupMenuButton<String>(
                              enabled: !busy,
                              icon: const Icon(Icons.more_vert),
                              onSelected: (v) {
                                switch (v) {
                                  case 'edit':
                                    onEdit();
                                  case 'time':
                                    onLogTime();
                                  case 'evaluate':
                                    onEvaluate();
                                  case 'next':
                                    onMoveNext();
                                  case 'delete':
                                    onDelete();
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'))),
                                PopupMenuItem(value: 'time', child: ListTile(leading: Icon(Icons.timer_outlined), title: Text('Log time'))),
                                PopupMenuItem(value: 'evaluate', child: ListTile(leading: Icon(Icons.rate_review_outlined), title: Text('Evaluate'))),
                                PopupMenuItem(value: 'next', child: ListTile(leading: Icon(Icons.redo_rounded), title: Text('Move to next week'))),
                                PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete'))),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Actual vs estimated time on a task card, with a one-tap "Log" button.
class _TimeRow extends StatelessWidget {
  final WeeklyTaskModel task;
  final VoidCallback? onLog;

  const _TimeRow({required this.task, required this.onLog});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final actual = task.actualHours;
    final est = task.estimatedHours;
    final over = actual != null && actual > est + 1e-9;

    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 15, color: over ? semantic.warning : cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          actual == null ? 'No time logged' : '${PlannerStyle.hours(actual)} / ${PlannerStyle.hours(est)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: actual == null ? FontWeight.w500 : FontWeight.w700,
            color: actual == null ? cs.onSurfaceVariant : (over ? semantic.warning : null),
          ),
        ),
        if (actual != null) ...[
          const SizedBox(width: 10),
          Expanded(child: TimeTrackBar(estimated: est, actual: actual, height: 6)),
          if (over) ...[
            const SizedBox(width: 8),
            Text(
              '+${PlannerStyle.hours(actual - est)} over',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: semantic.warning),
            ),
          ],
        ] else
          const Spacer(),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: onLog,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.add_alarm_outlined, size: 16),
          label: const Text('Log'),
        ),
      ],
    );
  }
}

/// "+4h extra hours" badge on extra-hours items.
class _ExtraBadge extends StatelessWidget {
  final double hours;
  final Color color;

  const _ExtraBadge({required this.hours, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Extra working hours: counted as planned work and added to the week\'s capacity and this area\'s budget',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_time_outlined, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              '+${PlannerStyle.hours(hours)} extra hours',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
