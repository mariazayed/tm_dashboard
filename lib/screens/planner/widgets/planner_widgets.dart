import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../enums/plan_item_status_enum.dart';
import '../../../models/planner_models.dart';
import '../../../theme/app_theme.dart';
import '../planner_style.dart';

/// Rounded surface used by every Planner panel.
class PlannerPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  const PlannerPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Small uppercase heading with an optional trailing widget.
class PanelTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const PanelTitle({super.key, required this.title, this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// "< Week 39 · Sep 21 – 27, 2026 >" header with a jump-to-current button.
class PeriodNavigator extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onCurrent;
  final String currentLabel;

  const PeriodNavigator({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPrevious,
    required this.onNext,
    this.onCurrent,
    required this.currentLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        _NavButton(icon: Icons.chevron_left, onTap: onPrevious, tooltip: 'Previous'),
        const SizedBox(width: 8),
        _NavButton(icon: Icons.chevron_right, onTap: onNext, tooltip: 'Next'),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onCurrent != null)
          TextButton.icon(
            onPressed: onCurrent,
            icon: const Icon(Icons.today_outlined, size: 18),
            label: Text(currentLabel),
          ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _NavButton({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Donut showing planned hours against capacity; turns red when over.
class CapacityRing extends StatelessWidget {
  final double planned;
  final double capacity;
  final double size;

  const CapacityRing({
    super.key,
    required this.planned,
    required this.capacity,
    this.size = 132,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final ratio = capacity > 0 ? planned / capacity : (planned > 0 ? 1.0 : 0.0);
    final over = planned > capacity + 1e-9;
    final color = over ? semantic.loss : cs.primary;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: ratio.clamp(0, 1).toDouble()),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(
            progress: value,
            color: color,
            track: cs.surfaceContainerHighest,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  PlannerStyle.pct(ratio * 100),
                  style: TextStyle(
                    fontSize: size * 0.2,
                    fontWeight: FontWeight.w800,
                    color: over ? semantic.loss : null,
                  ),
                ),
                Text(
                  'planned',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _RingPainter({required this.progress, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base);

    if (progress <= 0) return;
    final fg = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [color.withValues(alpha: 0.65), color],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// Hero card at the top of the week/month views: capacity ring plus the
/// numbers behind it.
class CapacityCard extends StatelessWidget {
  final PlanPeriodModel period;
  final String capacityLabel;
  final Widget? action;

  const CapacityCard({
    super.key,
    required this.period,
    required this.capacityLabel,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final remaining = period.remainingHours;

    final stats = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        StatTile(label: capacityLabel, value: PlannerStyle.hours(period.capacityHours), icon: Icons.timelapse_outlined),
        StatTile(label: 'Planned', value: PlannerStyle.hours(period.plannedHours), icon: Icons.event_note_outlined),
        StatTile(
          label: remaining >= 0 ? 'Free' : 'Over by',
          value: PlannerStyle.hours(remaining.abs()),
          icon: remaining >= 0 ? Icons.hourglass_empty_outlined : Icons.warning_amber_rounded,
          color: remaining >= 0 ? semantic.profit : semantic.loss,
        ),
        StatTile(
          label: 'Logged',
          value: PlannerStyle.hours(period.evaluation.actualHours),
          icon: Icons.timer_outlined,
          color: period.evaluation.actualHours > period.plannedHours + 1e-9 ? semantic.warning : null,
        ),
        StatTile(label: 'Working days', value: '${period.workingDays}', icon: Icons.work_history_outlined),
        StatTile(
          label: 'Extra hours',
          value: period.extraHours > 0 ? '+${PlannerStyle.hours(period.extraHours)}' : '—',
          icon: Icons.more_time_outlined,
          color: period.extraHours > 0 ? semantic.info : null,
        ),
      ],
    );

    return PlannerPanel(
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 460;
          final ring = CapacityRing(planned: period.plannedHours, capacity: period.capacityHours);
          final body = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              stats,
              if (action != null) ...[const SizedBox(height: 14), action!],
            ],
          );
          if (narrow) {
            return Column(children: [ring, const SizedBox(height: 16), body]);
          }
          return Row(
            children: [
              ring,
              const SizedBox(width: 24),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = color ?? cs.primary;
    return Container(
      constraints: const BoxConstraints(minWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Colored pill with a Focus Area's icon + name.
class AreaTag extends StatelessWidget {
  final FocusAreaModel area;
  final bool dense;

  const AreaTag({super.key, required this.area, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final color = PlannerStyle.colorFromHex(area.color);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PlannerStyle.iconFor(area.icon), size: dense ? 12 : 14, color: color),
          const SizedBox(width: 5),
          Text(
            area.name,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Round icon badge in a Focus Area's color.
class AreaIconBadge extends StatelessWidget {
  final FocusAreaModel area;
  final double size;

  const AreaIconBadge({super.key, required this.area, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final color = PlannerStyle.colorFromHex(area.color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(PlannerStyle.iconFor(area.icon), color: color, size: size * 0.5),
    );
  }
}

/// Per-Focus-Area budget bars: planned hours against the area's allowance
/// (capacity x max %). Over-limit areas turn red with a warning -- saving
/// is never blocked.
class AllocationPanel extends StatelessWidget {
  final List<AreaAllocationModel> areas;
  final bool showActual;
  final String title;
  /// Regular (weekday) hours of the period -- what each max % applies to.
  final double? regularHours;

  const AllocationPanel({
    super.key,
    required this.areas,
    this.showActual = false,
    this.title = 'Focus Area budget',
    this.regularHours,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final overCount = areas.where((a) => a.overLimit).length;

    return PlannerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelTitle(
            title: title,
            icon: Icons.donut_small_outlined,
            trailing: overCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: semantic.loss.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$overCount over limit',
                      style: TextStyle(color: semantic.loss, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  )
                : null,
          ),
          if (areas.isEmpty)
            Text('No Focus Areas yet.', style: TextStyle(color: cs.onSurfaceVariant))
          else
            ...areas.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AllocationRow(allocation: a, showActual: showActual, regularHours: regularHours),
                )),
        ],
      ),
    );
  }
}

class AllocationRow extends StatelessWidget {
  final AreaAllocationModel allocation;
  final bool showActual;
  final double? regularHours;

  const AllocationRow({super.key, required this.allocation, this.showActual = false, this.regularHours});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final a = allocation;
    final color = a.overLimit ? semantic.loss : PlannerStyle.colorFromHex(a.focusArea.color);
    final budgetUse = a.allowedHours > 0 ? a.plannedHours / a.allowedHours : (a.plannedHours > 0 ? 2.0 : 0.0);
    final actualUse = a.allowedHours > 0 ? a.actualHours / a.allowedHours : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AreaIconBadge(area: a.focusArea, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                a.focusArea.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (a.extraHours > 0) ...[
              Tooltip(
                message: '${PlannerStyle.hours(a.extraHours)} extra hours dedicated to this area',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: semantic.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${PlannerStyle.hours(a.extraHours)}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: semantic.info),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            if (a.overLimit) ...[
              Icon(Icons.warning_amber_rounded, size: 16, color: semantic.loss),
              const SizedBox(width: 4),
            ],
            Text(
              '${PlannerStyle.hours(a.plannedHours)} / ${PlannerStyle.hours(a.allowedHours)}',
              style: TextStyle(fontWeight: FontWeight.w700, color: a.overLimit ? semantic.loss : null),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _BudgetBar(use: budgetUse, color: color, track: cs.surfaceContainerHighest),
        if (showActual) ...[
          const SizedBox(height: 4),
          _BudgetBar(
            use: actualUse,
            color: color.withValues(alpha: 0.45),
            track: Colors.transparent,
            height: 5,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          // Percentages are of the area's own budget, and the budget is spelled
          // out, so extra hours can't make max % look inconsistent.
          '${PlannerStyle.pct(a.budgetUsedPct)} of budget'
          '${showActual ? ' · ${PlannerStyle.hours(a.actualHours)} actual' : ''}'
          ' · ${PlannerStyle.pct(a.maxPercent)}${regularHours != null ? ' of ${PlannerStyle.hours(regularHours!)}' : ''}'
          '${a.extraHours > 0 ? ' + ${PlannerStyle.hours(a.extraHours)} extra' : ''}'
          '${a.overLimit ? ' · over by ${PlannerStyle.hours(a.plannedHours - a.allowedHours)}' : ''}',
          style: TextStyle(fontSize: 12, color: a.overLimit ? semantic.loss : cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _BudgetBar extends StatelessWidget {
  final double use;
  final Color color;
  final Color track;
  final double height;

  const _BudgetBar({required this.use, required this.color, required this.track, this.height = 10});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Container(color: track),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: use.clamp(0, 1).toDouble()),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Container(
                  width: c.maxWidth * v,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color.withValues(alpha: 0.7), color]),
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status chip for an item's evaluation outcome.
class StatusPill extends StatelessWidget {
  final PlanItemStatusEnum status;

  const StatusPill({super.key, required this.status});

  static Color colorOf(BuildContext context, PlanItemStatusEnum status) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    switch (status) {
      case PlanItemStatusEnum.DONE:
        return semantic.profit;
      case PlanItemStatusEnum.PARTIAL:
        return semantic.warning;
      case PlanItemStatusEnum.MISSED:
        return semantic.loss;
      case PlanItemStatusEnum.PLANNED:
        return cs.onSurfaceVariant;
    }
  }

  static IconData iconOf(PlanItemStatusEnum status) {
    switch (status) {
      case PlanItemStatusEnum.DONE:
        return Icons.check_circle_rounded;
      case PlanItemStatusEnum.PARTIAL:
        return Icons.timelapse_rounded;
      case PlanItemStatusEnum.MISSED:
        return Icons.cancel_rounded;
      case PlanItemStatusEnum.PLANNED:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorOf(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconOf(status), size: 13, color: color),
          const SizedBox(width: 4),
          Text(status.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// 1-5 stars; interactive when [onChanged] is set (tap the current value
/// again to clear it).
class ScoreStars extends StatelessWidget {
  final int? score;
  final ValueChanged<int?>? onChanged;
  final double size;

  const ScoreStars({super.key, this.score, this.onChanged, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = score != null && i < score!;
        final star = Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: filled ? semantic.warning : cs.outline,
        );
        if (onChanged == null) return star;
        return InkWell(
          borderRadius: BorderRadius.circular(size),
          onTap: () => onChanged!(score == i + 1 ? null : i + 1),
          child: Padding(padding: const EdgeInsets.all(2), child: star),
        );
      }),
    );
  }
}

/// Three one-tap outcome buttons used in Evaluate mode. Tapping the
/// active outcome again resets the item to "not evaluated".
class QuickStatusButtons extends StatelessWidget {
  final PlanItemStatusEnum status;
  final ValueChanged<PlanItemStatusEnum> onChanged;
  final bool busy;

  const QuickStatusButtons({
    super.key,
    required this.status,
    required this.onChanged,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    const options = [PlanItemStatusEnum.DONE, PlanItemStatusEnum.PARTIAL, PlanItemStatusEnum.MISSED];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((o) {
        final selected = status == o;
        final color = StatusPill.colorOf(context, o);
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Tooltip(
            message: selected ? 'Reset evaluation' : o.label,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: busy ? null : () => onChanged(selected ? PlanItemStatusEnum.PLANNED : o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: selected ? color : color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  StatusPill.iconOf(o),
                  size: 18,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Completion %, outcome counts, average score and planned-vs-actual hours.
class EvaluationSummaryCard extends StatelessWidget {
  final EvaluationSummaryModel summary;
  final String title;

  const EvaluationSummaryCard({super.key, required this.summary, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final s = summary;

    Widget count(String label, int value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        );

    return PlannerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelTitle(title: title, icon: Icons.fact_check_outlined),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                PlannerStyle.pct(s.completionPct),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('completion', style: TextStyle(color: cs.onSurfaceVariant)),
              ),
              const Spacer(),
              if (s.averageScore != null) ...[
                ScoreStars(score: s.averageScore!.round(), size: 16),
                const SizedBox(width: 6),
                Text(s.averageScore!.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: s.totalCount == 0
                  ? Container(color: cs.surfaceContainerHighest)
                  : Row(
                      children: [
                        if (s.doneCount > 0) Expanded(flex: s.doneCount, child: Container(color: semantic.profit)),
                        if (s.partialCount > 0) Expanded(flex: s.partialCount, child: Container(color: semantic.warning)),
                        if (s.missedCount > 0) Expanded(flex: s.missedCount, child: Container(color: semantic.loss)),
                        if (s.pendingCount > 0)
                          Expanded(flex: s.pendingCount, child: Container(color: cs.surfaceContainerHighest)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              count('Done', s.doneCount, semantic.profit),
              const SizedBox(width: 8),
              count('Partial', s.partialCount, semantic.warning),
              const SizedBox(width: 8),
              count('Missed', s.missedCount, semantic.loss),
              const SizedBox(width: 8),
              count('Pending', s.pendingCount, cs.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.schedule_outlined, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '${PlannerStyle.hours(s.actualHours)} actual of ${PlannerStyle.hours(s.plannedHours)} planned',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Friendly empty state with an optional call to action.
class PlannerEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PlannerEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: cs.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Plan / Evaluate mode toggle shared by the week and month views.
enum PlannerMode { plan, evaluate }

class PlannerModeToggle extends StatelessWidget {
  final PlannerMode mode;
  final ValueChanged<PlannerMode> onChanged;

  const PlannerModeToggle({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PlannerMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: PlannerMode.plan, icon: Icon(Icons.edit_calendar_outlined, size: 18), label: Text('Plan')),
        ButtonSegment(value: PlannerMode.evaluate, icon: Icon(Icons.rate_review_outlined, size: 18), label: Text('Evaluate')),
      ],
      selected: {mode},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// Top of a bottom sheet: title + close button.
class SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SheetHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

/// Container for bottom sheets, matching AddGoalSheet's look.
class PlannerSheet extends StatelessWidget {
  final List<Widget> children;

  const PlannerSheet({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      padding: EdgeInsets.fromLTRB(20, 24, 20, 32 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(shrinkWrap: true, children: children),
        ),
      ),
    );
  }
}

/// Opens a Planner bottom sheet and returns its result.
Future<T?> showPlannerSheet<T>(BuildContext context, Widget sheet) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => sheet,
  );
}

/// Hour quick-pick chips + numeric field.
class HoursInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final List<double> presets;
  final VoidCallback? onChanged;

  const HoursInput({
    super.key,
    required this.controller,
    required this.label,
    this.presets = const [1, 2, 4, 6, 8],
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, suffixText: 'hours'),
          onChanged: (_) => onChanged?.call(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: presets
              .map((h) => ActionChip(
                    label: Text(PlannerStyle.hours(h)),
                    onPressed: () {
                      controller.text = h == h.roundToDouble() ? h.toInt().toString() : h.toString();
                      onChanged?.call();
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// Multi-line text area used for task/objective titles, notes and
/// evaluation write-ups: grows with its content, label pinned to the top,
/// and Enter inserts a new line.
class PlannerTextArea extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int minLines;
  final int maxLines;
  final bool autofocus;
  final IconData? icon;
  final ValueChanged<String>? onChanged;

  const PlannerTextArea({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.minLines = 3,
    this.maxLines = 8,
    this.autofocus = false,
    this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        prefixIcon: icon == null
            ? null
            : Padding(
                padding: EdgeInsets.only(bottom: (minLines - 1) * 20.0),
                child: Icon(icon, size: 20),
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
      ),
    );
  }
}

/// Actual time vs estimate. The estimate is the 100% mark: below it the bar
/// fills toward the estimate; past it the bar rescales so the overrun beyond
/// the estimate marker shows in the warning color -- going over is allowed
/// and made visible, never capped. Built from flex children (no
/// LayoutBuilder) so it can live inside IntrinsicHeight cards.
class TimeTrackBar extends StatelessWidget {
  final double estimated;
  final double actual;
  final double height;

  const TimeTrackBar({super.key, required this.estimated, required this.actual, this.height = 6});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final over = actual > estimated + 1e-9;
    final scale = over ? actual : (estimated > 0 ? estimated : 1.0);
    final estFrac = estimated > 0 ? (estimated / scale).clamp(0, 1).toDouble() : 0.0;
    final actFrac = (actual / scale).clamp(0, 1).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final within = (over ? estFrac : actFrac) * t;
        final overrun = over ? (actFrac - estFrac) * t : 0.0;
        final rest = (1 - within - overrun).clamp(0, 1).toDouble();
        int f(double v) => (v * 1000).round();

        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(height),
                  child: Row(
                    children: [
                      if (f(within) > 0)
                        Expanded(
                          flex: f(within),
                          child: ColoredBox(color: over || actFrac >= 1 ? semantic.profit : cs.primary),
                        ),
                      if (f(overrun) > 0)
                        Expanded(flex: f(overrun), child: ColoredBox(color: semantic.warning)),
                      if (f(rest) > 0) Expanded(flex: f(rest), child: const SizedBox()),
                    ],
                  ),
                ),
              ),
              if (over && estimated > 0)
                Positioned.fill(
                  top: -2,
                  bottom: -2,
                  child: Align(
                    alignment: Alignment(estFrac * 2 - 1, 0),
                    child: Container(width: 2, color: cs.onSurface),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
