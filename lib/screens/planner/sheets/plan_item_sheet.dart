import 'package:flutter/material.dart';

import '../../../models/planner_models.dart';
import '../../../theme/app_theme.dart';
import '../planner_style.dart';
import '../widgets/planner_widgets.dart';

/// What the sheet hands back to its caller on save.
class PlanItemDraft {
  final String title;
  final int focusAreaId;
  final double estimatedHours;
  final String notes;
  final int? monthlyObjectiveId;

  const PlanItemDraft({
    required this.title,
    required this.focusAreaId,
    required this.estimatedHours,
    required this.notes,
    this.monthlyObjectiveId,
  });
}

/// Add/edit sheet shared by weekly tasks and monthly objectives. Shows a
/// live preview of the chosen Focus Area's budget so the user sees before
/// saving whether this item pushes the area over its max % (a warning
/// only -- saving is always allowed).
class PlanItemSheet extends StatefulWidget {
  final bool isMonthly;
  final String periodLabel;
  final List<FocusAreaModel> areas;
  final PlanPeriodModel period;
  final List<MonthlyObjectiveModel> objectives;

  // Editing an existing item.
  final int? editingId;
  final String? initialTitle;
  final int? initialAreaId;
  final double? initialHours;
  final String? initialNotes;
  final int? initialObjectiveId;

  final Future<void> Function(PlanItemDraft draft) onSubmit;

  const PlanItemSheet({
    super.key,
    required this.isMonthly,
    required this.periodLabel,
    required this.areas,
    required this.period,
    this.objectives = const [],
    this.editingId,
    this.initialTitle,
    this.initialAreaId,
    this.initialHours,
    this.initialNotes,
    this.initialObjectiveId,
    required this.onSubmit,
  });

  @override
  State<PlanItemSheet> createState() => _PlanItemSheetState();
}

class _PlanItemSheetState extends State<PlanItemSheet> {
  late final TextEditingController _title;
  late final TextEditingController _hours;
  late final TextEditingController _notes;
  int? _areaId;
  int? _objectiveId;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.editingId != null;
  String get _noun => widget.isMonthly ? 'Objective' : 'Task';

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle ?? '');
    final h = widget.initialHours;
    _hours = TextEditingController(
      text: h == null ? '' : (h == h.roundToDouble() ? h.toInt().toString() : h.toString()),
    );
    _notes = TextEditingController(text: widget.initialNotes ?? '');
    _areaId = widget.initialAreaId ?? (widget.areas.isNotEmpty ? widget.areas.first.id : null);
    _objectiveId = widget.initialObjectiveId;
  }

  @override
  void dispose() {
    _title.dispose();
    _hours.dispose();
    _notes.dispose();
    super.dispose();
  }

  double get _enteredHours => double.tryParse(_hours.text.trim().replaceAll(',', '.')) ?? 0;

  /// Picking an objective defaults the Focus Area to the objective's.
  void _pickObjective(int? id) {
    setState(() {
      _objectiveId = id;
      if (id != null) {
        final o = widget.objectives.where((o) => o.id == id).firstOrNull;
        if (o != null && widget.areas.any((a) => a.id == o.focusArea.id)) {
          _areaId = o.focusArea.id;
        }
      }
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give the ${_noun.toLowerCase()} a title');
      return;
    }
    if (_areaId == null) {
      setState(() => _error = 'Pick a Focus Area');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(PlanItemDraft(
        title: title,
        focusAreaId: _areaId!,
        estimatedHours: _enteredHours,
        notes: _notes.text.trim(),
        monthlyObjectiveId: _objectiveId,
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PlannerSheet(
      children: [
        SheetHeader(
          title: _isEdit ? 'Edit $_noun' : 'New $_noun',
          subtitle: widget.periodLabel,
        ),
        PlannerTextArea(
          controller: _title,
          autofocus: !_isEdit,
          minLines: 2,
          maxLines: 6,
          label: widget.isMonthly ? 'Objective' : 'Task',
          hint: widget.isMonthly
              ? 'e.g. Backtest the London breakout on 3 pairs and write up the results'
              : 'e.g. Review last week\'s trades and tag every mistake',
        ),
        const SizedBox(height: 20),
        if (!widget.isMonthly && widget.objectives.isNotEmpty) ...[
          DropdownButtonFormField<int?>(
            initialValue: widget.objectives.any((o) => o.id == _objectiveId) ? _objectiveId : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Contributes to monthly objective (optional)',
              prefixIcon: Icon(Icons.track_changes_outlined),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('None')),
              ...widget.objectives.map((o) => DropdownMenuItem<int?>(
                    value: o.id,
                    child: Text('${o.title}  ·  ${o.monthLabel}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: _pickObjective,
          ),
          const SizedBox(height: 20),
        ],
        Text('Focus Area', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.areas.map((a) {
            final selected = a.id == _areaId;
            final color = PlannerStyle.colorFromHex(a.color);
            return ChoiceChip(
              selected: selected,
              showCheckmark: false,
              avatar: Icon(PlannerStyle.iconFor(a.icon), size: 16, color: selected ? Colors.white : color),
              label: Text(a.name),
              labelStyle: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: FontWeight.w600,
              ),
              selectedColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.4)),
              onSelected: (_) => setState(() => _areaId = a.id),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        HoursInput(
          controller: _hours,
          label: 'Estimated time',
          presets: widget.isMonthly ? const [4, 8, 12, 20, 30] : const [0.5, 1, 2, 4, 6],
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 16),
        _BudgetPreview(
          period: widget.period,
          area: widget.areas.where((a) => a.id == _areaId).firstOrNull,
          hours: _enteredHours,
          initialAreaId: widget.initialAreaId,
          initialHours: widget.initialHours ?? 0,
          isEdit: _isEdit,
        ),
        const SizedBox(height: 16),
        PlannerTextArea(
          controller: _notes,
          label: 'Notes (optional)',
          hint: 'Context, links, definition of done…',
          minLines: 3,
          maxLines: 10,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: context.semanticColors.loss)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                  )
                : Text(_isEdit ? 'Save changes' : 'Add $_noun'),
          ),
        ),
      ],
    );
  }
}

class _BudgetPreview extends StatelessWidget {
  final PlanPeriodModel period;
  final FocusAreaModel? area;
  final double hours;
  final int? initialAreaId;
  final double initialHours;
  final bool isEdit;

  const _BudgetPreview({
    required this.period,
    required this.area,
    required this.hours,
    required this.initialAreaId,
    required this.initialHours,
    required this.isEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (area == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;

    final alloc = period.areas.where((a) => a.focusArea.id == area!.id).firstOrNull;
    final capacity = period.capacityHours;
    final allowed = alloc?.allowedHours ?? capacity * area!.maxPercent / 100;
    final double existingInArea = alloc?.plannedHours ?? 0.0;
    final double minusSelf = isEdit && initialAreaId == area!.id ? initialHours : 0.0;
    final double newAreaTotal = existingInArea - minusSelf + hours;
    final double newPeriodTotal = period.plannedHours - (isEdit ? initialHours : 0.0) + hours;

    final areaOver = newAreaTotal > allowed + 1e-9;
    final periodOver = newPeriodTotal > capacity + 1e-9;
    final color = areaOver ? semantic.loss : PlannerStyle.colorFromHex(area!.color);
    final use = allowed > 0 ? (newAreaTotal / allowed).clamp(0, 1).toDouble() : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(areaOver ? Icons.warning_amber_rounded : Icons.donut_small_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${area!.name} budget after this',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${PlannerStyle.hours(newAreaTotal)} / ${PlannerStyle.hours(allowed)}',
                style: TextStyle(fontWeight: FontWeight.w800, color: areaOver ? semantic.loss : null),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: use,
              minHeight: 8,
              color: color,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            areaOver
                ? 'Over the ${PlannerStyle.pct(area!.maxPercent)} limit by ${PlannerStyle.hours(newAreaTotal - allowed)} — you can still save.'
                : '${PlannerStyle.hours(allowed - newAreaTotal)} left in this area (max ${PlannerStyle.pct(area!.maxPercent)}).',
            style: TextStyle(fontSize: 12, color: areaOver ? semantic.loss : cs.onSurfaceVariant),
          ),
          if (periodOver)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Total plan would be ${PlannerStyle.hours(newPeriodTotal)} of ${PlannerStyle.hours(capacity)} capacity.',
                style: TextStyle(fontSize: 12, color: semantic.loss),
              ),
            ),
        ],
      ),
    );
  }
}
