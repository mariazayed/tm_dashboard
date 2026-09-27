import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../constants/route_names.dart';
import '../../enums/plan_item_status_enum.dart';
import '../../models/planner_models.dart';
import '../../services/planner_service.dart';
import '../../theme/app_theme.dart';
import '../planner/planner_style.dart';
import '../planner/widgets/planner_widgets.dart';

/// Home-dashboard "Planner" section. Self-fetching (one call to
/// GET /planner/overview) like GoalsProgressSection, and made of:
///
/// - smart nudges (plan your week / close the week / over budget / streaks)
/// - Week pulse: capacity ring, completion, streaks and the next tasks up
/// - Focus mix: this week's planned hours per Focus Area as a donut, each
///   area checked against its max %
/// - 8-week rhythm: capacity vs planned vs actual hours per week, with the
///   completion % of each week underneath
/// - This month's objectives with their rolled-up progress
class PlannerDashboardSection extends StatefulWidget {
  final bool wide;

  const PlannerDashboardSection({super.key, required this.wide});

  @override
  State<PlannerDashboardSection> createState() => _PlannerDashboardSectionState();
}

class _PlannerDashboardSectionState extends State<PlannerDashboardSection> {
  PlannerOverviewModel? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await PlannerService.getOverview(weeks: 8);
      if (!mounted) return;
      setState(() {
        _data = data;
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

  void _openPlanner() => context.goNamed(RouteNames.planner);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = _data;
    final week = data?.currentWeek;

    final header = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Planner',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              if (week != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Week ${PlannerStyle.isoWeek(week.weekStart)} · ${PlannerStyle.weekRange(week.weekStart)} · '
                  '${data!.daysLeftInWeek} day${data.daysLeftInWeek == 1 ? '' : 's'} left',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        IconButton(tooltip: 'Refresh', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh, size: 20)),
        FilledButton.tonalIcon(
          onPressed: _openPlanner,
          icon: const Icon(Icons.checklist_rtl_outlined, size: 18),
          label: const Text('Open Planner'),
        ),
      ],
    );

    Widget body;
    if (_loading && data == null) {
      body = _Skeleton(wide: widget.wide);
    } else if (data == null) {
      body = PlannerPanel(
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Couldn\'t load the planner: $_error', style: TextStyle(color: cs.onSurfaceVariant)),
            ),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    } else if (data.currentWeek.areas.isEmpty && data.history.every((w) => w.taskCount == 0)) {
      body = PlannerPanel(
        child: PlannerEmptyState(
          icon: Icons.checklist_rtl_outlined,
          title: 'Plan your trading work week by week',
          message: 'Create Focus Areas (Backtesting, Journaling, Learning…), set your working hours, '
              'then plan and evaluate your week. Your progress will show up here.',
          actionLabel: 'Set up the Planner',
          onAction: _openPlanner,
        ),
      );
    } else {
      body = _buildContent(data);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 16),
        body,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContent(PlannerOverviewModel data) {
    final nudges = _nudges(context, data);
    final pulse = _WeekPulseCard(data: data, onOpen: _openPlanner);
    final mix = _FocusMixCard(week: data.currentWeek);
    final rhythm = _RhythmCard(history: data.history);
    final month = _MonthObjectivesCard(month: data.currentMonth, onOpen: _openPlanner);

    if (widget.wide) {
      return Column(
        children: [
          if (nudges.isNotEmpty) ...[_NudgeStrip(nudges: nudges, onAction: _openPlanner), const SizedBox(height: 16)],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: pulse),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: mix),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: rhythm),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: month),
            ],
          ),
        ],
      );
    }
    return Column(
      children: [
        if (nudges.isNotEmpty) ...[_NudgeStrip(nudges: nudges, onAction: _openPlanner), const SizedBox(height: 16)],
        pulse,
        const SizedBox(height: 16),
        mix,
        const SizedBox(height: 16),
        rhythm,
        const SizedBox(height: 16),
        month,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Nudges

class _Nudge {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? action;

  const _Nudge(this.icon, this.color, this.title, this.message, [this.action]);
}

/// Picks up to two context-aware prompts, most urgent first.
List<_Nudge> _nudges(BuildContext context, PlannerOverviewModel d) {
  final semantic = context.semanticColors;
  final cs = Theme.of(context).colorScheme;
  final w = d.currentWeek;
  final out = <_Nudge>[];

  if (w.tasks.isEmpty) {
    out.add(_Nudge(Icons.edit_calendar_outlined, cs.primary, 'Plan this week',
        'Nothing is planned yet — you have ${PlannerStyle.hours(w.capacityHours)} to work with.', 'Plan now'));
  }
  if (w.overCapacity) {
    out.add(_Nudge(Icons.warning_amber_rounded, semantic.loss, 'Over capacity',
        'You planned ${PlannerStyle.hours(w.plannedHours)} but have ${PlannerStyle.hours(w.capacityHours)}. '
            'Trim tasks or add extra hours.', 'Rebalance'));
  }
  final over = w.areas.where((a) => a.overLimit).toList();
  if (over.isNotEmpty) {
    final a = over.first;
    out.add(_Nudge(Icons.donut_small_outlined, semantic.warning,
        '${a.focusArea.name} is over budget',
        '${PlannerStyle.hours(a.plannedHours)} planned vs ${PlannerStyle.hours(a.allowedHours)} allowed '
            '(max ${PlannerStyle.pct(a.maxPercent)})${over.length > 1 ? ' · +${over.length - 1} more area${over.length > 2 ? 's' : ''}' : ''}.',
        'Review'));
  }
  final pending = w.evaluation.pendingCount;
  if (d.daysLeftInWeek <= 2 && pending > 0) {
    out.add(_Nudge(Icons.rate_review_outlined, semantic.info, 'Close the week',
        '${d.daysLeftInWeek == 1 ? 'Last day' : '2 days left'} — $pending task${pending == 1 ? '' : 's'} still to evaluate.',
        'Evaluate'));
  }
  if (d.history.length >= 2) {
    final last = d.history[d.history.length - 2];
    final missing = last.taskCount - last.evaluatedCount;
    if (missing > 0) {
      out.add(_Nudge(Icons.history_outlined, semantic.orange, 'Last week isn\'t closed',
          '$missing task${missing == 1 ? '' : 's'} from the week of ${DateFormat('MMM d').format(last.weekStart)} still need an outcome.',
          'Evaluate'));
    }
  }
  if (out.isEmpty) {
    if (d.evaluationStreak >= 2) {
      out.add(_Nudge(Icons.local_fire_department_outlined, semantic.profit, '${d.evaluationStreak}-week review streak',
          'Every task evaluated for ${d.evaluationStreak} weeks straight. Keep the loop going.'));
    } else {
      out.add(_Nudge(Icons.verified_outlined, semantic.profit, 'On track',
          '${PlannerStyle.pct(w.evaluation.completionPct)} done so far · ${PlannerStyle.hours(w.remainingHours.clamp(0, double.infinity).toDouble())} free this week.'));
    }
  }
  return out.take(2).toList();
}

class _NudgeStrip extends StatelessWidget {
  final List<_Nudge> nudges;
  final VoidCallback onAction;

  const _NudgeStrip({required this.nudges, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final cards = nudges.map((n) => _NudgeCard(nudge: n, onAction: onAction)).toList();
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 700 || cards.length == 1) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                cards[i],
              ],
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          ),
        );
      },
    );
  }
}

class _NudgeCard extends StatelessWidget {
  final _Nudge nudge;
  final VoidCallback onAction;

  const _NudgeCard({required this.nudge, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = nudge.color;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [c.withValues(alpha: 0.14), c.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(nudge.icon, color: c, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(nudge.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(nudge.message, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (nudge.action != null)
            TextButton(onPressed: onAction, child: Text(nudge.action!)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Week pulse

class _WeekPulseCard extends StatelessWidget {
  final PlannerOverviewModel data;
  final VoidCallback onOpen;

  const _WeekPulseCard({required this.data, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final w = data.currentWeek;
    final e = w.evaluation;

    final upNext = w.tasks.where((t) => t.status == PlanItemStatusEnum.PLANNED).toList()
      ..sort((a, b) => b.estimatedHours.compareTo(a.estimatedHours));

    final stats = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        StatTile(
          label: 'Completion',
          value: PlannerStyle.pct(e.completionPct),
          icon: Icons.task_alt_outlined,
          color: e.completionPct >= 70 ? semantic.profit : null,
        ),
        StatTile(label: 'Done', value: '${e.doneCount}/${e.totalCount}', icon: Icons.check_circle_outline),
        StatTile(
          label: 'Avg score',
          value: e.averageScore == null ? '—' : e.averageScore!.toStringAsFixed(1),
          icon: Icons.star_outline_rounded,
          color: e.averageScore == null ? null : semantic.warning,
        ),
        StatTile(
          label: 'Planning streak',
          value: '${data.planningStreak} wk',
          icon: Icons.local_fire_department_outlined,
          color: data.planningStreak >= 3 ? semantic.orange : null,
        ),
        StatTile(
          label: 'Review streak',
          value: '${data.evaluationStreak} wk',
          icon: Icons.fact_check_outlined,
          color: data.evaluationStreak >= 2 ? semantic.profit : null,
        ),
      ],
    );

    return PlannerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelTitle(
            title: 'Week pulse',
            icon: Icons.monitor_heart_outlined,
            trailing: Text(
              '${PlannerStyle.hours(w.plannedHours)} of ${PlannerStyle.hours(w.capacityHours)}'
              '${w.extraHours > 0 ? ' (+${PlannerStyle.hours(w.extraHours)} extra)' : ''}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: w.overCapacity ? semantic.loss : cs.onSurfaceVariant),
            ),
          ),
          LayoutBuilder(
            builder: (context, c) {
              final ring = CapacityRing(planned: w.plannedHours, capacity: w.capacityHours, size: 120);
              if (c.maxWidth < 420) {
                return Column(children: [ring, const SizedBox(height: 16), stats]);
              }
              return Row(
                children: [
                  ring,
                  const SizedBox(width: 20),
                  Expanded(child: stats),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Up next', style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface)),
              const SizedBox(width: 8),
              if (upNext.isNotEmpty)
                Text('${upNext.length} open · ${PlannerStyle.hours(upNext.fold<double>(0, (s, t) => s + t.estimatedHours))}',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),
          if (upNext.isEmpty)
            Text(
              w.tasks.isEmpty ? 'No tasks planned for this week yet.' : 'Everything this week has an outcome. 🎉',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            ...upNext.take(4).map((t) => _UpNextRow(task: t, onTap: onOpen)),
          if (upNext.length > 4)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: onOpen, child: Text('+${upNext.length - 4} more')),
            ),
        ],
      ),
    );
  }
}

class _UpNextRow extends StatelessWidget {
  final WeeklyTaskModel task;
  final VoidCallback onTap;

  const _UpNextRow({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = PlannerStyle.colorFromHex(task.focusArea.color);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(width: 4, height: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    task.monthlyObjectiveTitle != null ? '${task.focusArea.name} · ${task.monthlyObjectiveTitle}' : task.focusArea.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(PlannerStyle.hours(task.estimatedHours), style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Focus mix donut

class _FocusMixCard extends StatefulWidget {
  final WeekPlanModel week;

  const _FocusMixCard({required this.week});

  @override
  State<_FocusMixCard> createState() => _FocusMixCardState();
}

class _FocusMixCardState extends State<_FocusMixCard> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final areas = widget.week.areas.where((a) => a.plannedHours > 0).toList();
    final total = areas.fold<double>(0, (s, a) => s + a.plannedHours);
    final free = (widget.week.capacityHours - total).clamp(0, double.infinity).toDouble();
    final touched = _touched != null && _touched! < areas.length ? areas[_touched!] : null;

    final sections = <PieChartSectionData>[
      for (var i = 0; i < areas.length; i++)
        PieChartSectionData(
          value: areas[i].plannedHours,
          color: PlannerStyle.colorFromHex(areas[i].focusArea.color),
          radius: _touched == i ? 26 : 20,
          showTitle: false,
        ),
      if (free > 0)
        PieChartSectionData(
          value: free,
          color: cs.surfaceContainerHighest,
          radius: 16,
          showTitle: false,
        ),
    ];

    return PlannerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(title: 'Focus mix this week', icon: Icons.donut_large_outlined),
          if (areas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No hours planned yet', style: TextStyle(color: cs.onSurfaceVariant))),
            )
          else ...[
            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 58,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            final idx = response?.touchedSection?.touchedSectionIndex;
                            final next = (event.isInterestedForInteractions && idx != null && idx >= 0 && idx < areas.length) ? idx : null;
                            if (next != _touched) setState(() => _touched = next);
                          },
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          PlannerStyle.hours(touched?.plannedHours ?? total),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            touched?.focusArea.name ?? 'planned',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...[
              for (var i = 0; i < areas.length; i++)
                _MixLegendRow(
                  allocation: areas[i],
                  highlighted: _touched == i,
                  onHover: (h) => setState(() => _touched = h ? i : null),
                ),
            ],
            if (free > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: cs.surfaceContainerHighest, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Unplanned', style: TextStyle(color: cs.onSurfaceVariant))),
                    Text(PlannerStyle.hours(free), style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            if (widget.week.overCapacity)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Planned ${PlannerStyle.hours(total - widget.week.capacityHours)} beyond capacity.',
                  style: TextStyle(fontSize: 12, color: semantic.loss),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _MixLegendRow extends StatelessWidget {
  final AreaAllocationModel allocation;
  final bool highlighted;
  final ValueChanged<bool> onHover;

  const _MixLegendRow({required this.allocation, required this.highlighted, required this.onHover});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final a = allocation;
    final color = PlannerStyle.colorFromHex(a.focusArea.color);
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: highlighted ? color.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(a.focusArea.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (a.overLimit) ...[
              Icon(Icons.warning_amber_rounded, size: 14, color: semantic.loss),
              const SizedBox(width: 4),
            ],
            Text(
              '${PlannerStyle.pct(a.plannedPct)} / ${PlannerStyle.pct(a.maxPercent)}',
              style: TextStyle(fontSize: 12, color: a.overLimit ? semantic.loss : cs.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 42,
              child: Text(PlannerStyle.hours(a.plannedHours), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 8-week rhythm

class _RhythmCard extends StatelessWidget {
  final List<WeekSnapshotModel> history;

  const _RhythmCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final plannedColor = cs.primary.withValues(alpha: 0.45);
    final actualColor = cs.primary;
    final trackColor = cs.surfaceContainerHighest;

    double maxY = 1;
    for (final w in history) {
      for (final v in [w.capacityHours, w.plannedHours, w.actualHours]) {
        if (v > maxY) maxY = v;
      }
    }
    maxY = (maxY * 1.15).ceilToDouble();

    final past = history.length > 1 ? history.sublist(0, history.length - 1) : <WeekSnapshotModel>[];
    final measured = past.where((w) => w.taskCount > 0).toList();
    final avgCompletion = measured.isEmpty ? null : measured.fold<double>(0, (s, w) => s + w.completionPct) / measured.length;
    final totalActual = history.fold<double>(0, (s, w) => s + w.actualHours);
    final totalPlanned = history.fold<double>(0, (s, w) => s + w.plannedHours);
    final fmt = DateFormat('MMM d');

    Widget legend(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        );

    return PlannerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle(title: 'Rhythm · last 8 weeks', icon: Icons.stacked_bar_chart_outlined),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _BigNumber(
                value: avgCompletion == null ? '—' : PlannerStyle.pct(avgCompletion),
                label: 'avg completion',
              ),
              _BigNumber(
                value: totalPlanned == 0 ? '—' : PlannerStyle.pct(totalActual / totalPlanned * 100),
                label: 'of planned hours logged',
              ),
              _BigNumber(value: PlannerStyle.hours(totalActual), label: 'actual hours'),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 16, children: [legend(trackColor, 'Capacity'), legend(plannedColor, 'Planned'), legend(actualColor, 'Actual')]),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: semantic.chartGridLine.withValues(alpha: 0.4), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox();
                        return Text('${value.toInt()}h', style: TextStyle(fontSize: 10, color: semantic.chartAxisLabel));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= history.length) return const SizedBox();
                        final isNow = i == history.length - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            isNow ? 'Now' : fmt.format(history[i].weekStart),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isNow ? FontWeight.w800 : FontWeight.w500,
                              color: isNow ? cs.primary : semantic.chartAxisLabel,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => semantic.tooltipBackground,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (rodIndex != 0) return null;
                      final w = history[group.x];
                      return BarTooltipItem(
                        'Week of ${fmt.format(w.weekStart)}\n',
                        TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface, fontSize: 12),
                        textAlign: TextAlign.left,
                        children: [
                          TextSpan(
                            text: 'Capacity ${PlannerStyle.hours(w.capacityHours)}'
                                '${w.extraHours > 0 ? ' (+${PlannerStyle.hours(w.extraHours)} extra)' : ''}\n'
                                'Planned ${PlannerStyle.hours(w.plannedHours)} · Actual ${PlannerStyle.hours(w.actualHours)}\n'
                                '${w.taskCount == 0 ? 'No tasks' : '${w.doneCount}/${w.taskCount} done · ${PlannerStyle.pct(w.completionPct)}'}'
                                '${w.averageScore != null ? ' · ★ ${w.averageScore!.toStringAsFixed(1)}' : ''}',
                            style: TextStyle(fontWeight: FontWeight.w500, color: cs.onSurfaceVariant, fontSize: 11, height: 1.4),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < history.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 3,
                      barRods: [
                        BarChartRodData(
                          toY: history[i].plannedHours,
                          width: 11,
                          color: plannedColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: history[i].capacityHours,
                            color: trackColor,
                          ),
                        ),
                        BarChartRodData(
                          toY: history[i].actualHours,
                          width: 11,
                          color: actualColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Completion % per week, aligned under the bars.
          Row(
            children: [
              const SizedBox(width: 34),
              for (final w in history)
                Expanded(
                  child: Center(
                    child: Tooltip(
                      message: w.taskCount == 0 ? 'No tasks' : '${PlannerStyle.pct(w.completionPct)} complete',
                      child: _CompletionDot(pct: w.taskCount == 0 ? null : w.completionPct),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Center(child: Text('weekly completion', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))),
        ],
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  final String value;
  final String label;

  const _BigNumber({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.1)),
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

/// Small ring showing a week's completion; hollow when the week had no tasks.
class _CompletionDot extends StatelessWidget {
  final double? pct;

  const _CompletionDot({required this.pct});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final p = pct;
    final color = p == null
        ? cs.outlineVariant
        : p >= 80
            ? semantic.profit
            : p >= 50
                ? semantic.warning
                : semantic.loss;
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: p == null ? 0 : (p / 100).clamp(0, 1).toDouble(),
            strokeWidth: 3,
            color: color,
            backgroundColor: cs.surfaceContainerHighest,
          ),
          Text(
            p == null ? '·' : '${p.round()}',
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Month objectives

class _MonthObjectivesCard extends StatelessWidget {
  final MonthPlanModel month;
  final VoidCallback onOpen;

  const _MonthObjectivesCard({required this.month, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final objectives = List.of(month.objectives)..sort((a, b) => a.progressPct.compareTo(b.progressPct));
    final avg = objectives.isEmpty ? 0.0 : objectives.fold<double>(0, (s, o) => s + o.progressPct) / objectives.length;
    final now = DateTime.now();
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final timePct = (month.year == now.year && month.month == now.month) ? now.day / daysInMonth * 100 : 100.0;
    final behind = objectives.isNotEmpty && avg + 10 < timePct;

    return PlannerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelTitle(
            title: '${DateFormat('MMMM').format(DateTime(month.year, month.month))} objectives',
            icon: Icons.track_changes_outlined,
            trailing: Text(
              '${PlannerStyle.hours(month.plannedHours)} / ${PlannerStyle.hours(month.capacityHours)}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: month.overCapacity ? semantic.loss : cs.onSurfaceVariant),
            ),
          ),
          if (objectives.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No objectives set for this month.', style: TextStyle(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                TextButton.icon(onPressed: onOpen, icon: const Icon(Icons.add, size: 18), label: const Text('Set objectives')),
              ],
            )
          else ...[
            // Progress vs time elapsed in the month.
            _PaceBar(progress: avg, time: timePct),
            const SizedBox(height: 6),
            Text(
              behind
                  ? 'Behind pace — ${PlannerStyle.pct(avg)} done with ${PlannerStyle.pct(timePct)} of the month gone.'
                  : '${PlannerStyle.pct(avg)} average progress · ${PlannerStyle.pct(timePct)} of the month gone.',
              style: TextStyle(fontSize: 12, color: behind ? semantic.warning : cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            ...objectives.take(5).map((o) => _ObjectiveRow(objective: o)),
            if (objectives.length > 5)
              TextButton(onPressed: onOpen, child: Text('+${objectives.length - 5} more')),
          ],
        ],
      ),
    );
  }
}

class _PaceBar extends StatelessWidget {
  final double progress;
  final double time;

  const _PaceBar({required this.progress, required this.time});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return SizedBox(
          height: 18,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 5,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (progress / 100).clamp(0, 1).toDouble(),
                    minHeight: 8,
                    color: cs.primary,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
              ),
              // "Today" marker: how much of the month has elapsed.
              Positioned(
                left: (w * (time / 100).clamp(0, 1)).toDouble() - 1,
                top: 0,
                child: Tooltip(
                  message: '${PlannerStyle.pct(time)} of the month elapsed',
                  child: Container(width: 2, height: 18, color: cs.onSurface),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ObjectiveRow extends StatelessWidget {
  final MonthlyObjectiveModel objective;

  const _ObjectiveRow({required this.objective});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final o = objective;
    final color = o.progressPct >= 100 ? semantic.profit : PlannerStyle.colorFromHex(o.focusArea.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AreaIconBadge(area: o.focusArea, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(o.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text(PlannerStyle.pct(o.progressPct), style: TextStyle(fontWeight: FontWeight.w800, color: color)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (o.progressPct / 100).clamp(0, 1).toDouble(),
                    minHeight: 6,
                    color: color,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton

class _Skeleton extends StatelessWidget {
  final bool wide;

  const _Skeleton({required this.wide});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final surface = Theme.of(context).colorScheme.surface;
    Widget block(double h) => Container(
          height: h,
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20)),
        );
    return Shimmer.fromColors(
      baseColor: semantic.shimmerBase,
      highlightColor: semantic.shimmerHighlight,
      child: wide
          ? Column(
              children: [
                Row(children: [Expanded(flex: 3, child: block(260)), const SizedBox(width: 20), Expanded(flex: 2, child: block(260))]),
                const SizedBox(height: 20),
                Row(children: [Expanded(flex: 3, child: block(300)), const SizedBox(width: 20), Expanded(flex: 2, child: block(300))]),
              ],
            )
          : Column(children: [block(260), const SizedBox(height: 16), block(260), const SizedBox(height: 16), block(300)]),
    );
  }
}
