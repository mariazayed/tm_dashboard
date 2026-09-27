import 'package:flutter/material.dart';

import '../../../models/planner_models.dart';
import '../../../services/planner_service.dart';
import '../../../theme/app_theme.dart';
import '../planner_style.dart';
import '../widgets/planner_widgets.dart';

/// Add or edit extra working hours for a week. They're saved as an "extra"
/// task in the chosen Focus Area's list: planned work you can evaluate and
/// log time on, whose hours are also added to the week's capacity and to
/// that area's budget -- so the time left for your other tasks doesn't
/// change.
class ExtraHoursSheet extends StatefulWidget {
  final String weekLabel;
  final DateTime weekStart;
  final WeekPlanModel plan;
  final List<FocusAreaModel> areas;
  final WeeklyTaskModel? existing;

  const ExtraHoursSheet({
    super.key,
    required this.weekLabel,
    required this.weekStart,
    required this.plan,
    required this.areas,
    this.existing,
  });

  @override
  State<ExtraHoursSheet> createState() => _ExtraHoursSheetState();
}

class _ExtraHoursSheetState extends State<ExtraHoursSheet> {
  late final TextEditingController _hours;
  late final TextEditingController _title;
  int? _areaId;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final h = e?.estimatedHours;
    _hours = TextEditingController(text: h == null ? '' : (h == h.roundToDouble() ? h.toInt().toString() : h.toString()));
    _title = TextEditingController(text: e?.title ?? '');
    _areaId = e?.focusArea.id ?? _pickableAreas.firstOrNull?.id;
  }

  @override
  void dispose() {
    _hours.dispose();
    _title.dispose();
    super.dispose();
  }

  List<FocusAreaModel> get _pickableAreas {
    final list = widget.areas.where((a) => !a.archived).toList();
    final current = widget.existing?.focusArea;
    if (current != null && !list.any((a) => a.id == current.id)) list.add(current);
    return list;
  }

  double get _value => double.tryParse(_hours.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    final areaId = _areaId;
    if (_value <= 0) {
      setState(() => _error = 'Enter how many extra hours');
      return;
    }
    if (areaId == null) {
      setState(() => _error = 'Pick the Focus Area these hours are for');
      return;
    }
    final title = _title.text.trim().isEmpty ? 'Extra hours' : _title.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isEdit) {
        await PlannerService.updateTask(widget.existing!.id, {
          'title': title,
          'focusAreaId': areaId,
          'estimatedHours': _value,
        });
      } else {
        await PlannerService.createTask({
          'weekStart': plannerDateFormat.format(widget.weekStart),
          'title': title,
          'focusAreaId': areaId,
          'estimatedHours': _value,
          'notes': '',
          'extra': true,
        });
      }
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
    final semantic = context.semanticColors;
    final plan = widget.plan;
    final area = _pickableAreas.where((a) => a.id == _areaId).firstOrNull;

    // Before/after preview. When editing, take this item's current hours out
    // of the "before" numbers first.
    final double prev = widget.existing?.estimatedHours ?? 0.0;
    final prevAreaId = widget.existing?.focusArea.id;
    final capBefore = plan.capacityHours - prev;
    final capAfter = capBefore + _value;
    final alloc = area == null ? null : plan.areas.where((a) => a.focusArea.id == area.id).firstOrNull;
    final budgetBefore = area == null
        ? 0.0
        : (alloc?.allowedHours ?? plan.baseHours * area.maxPercent / 100) - (prevAreaId == area.id ? prev : 0.0);
    final budgetAfter = budgetBefore + _value;

    return PlannerSheet(
      children: [
        SheetHeader(title: _isEdit ? 'Edit extra hours' : 'Add extra hours', subtitle: widget.weekLabel),
        Text('Focus Area', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        if (_pickableAreas.isEmpty)
          Text('Create a Focus Area in Setup first — extra hours belong to one, just like tasks.',
              style: TextStyle(color: cs.onSurfaceVariant))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _pickableAreas.map((a) {
              final selected = a.id == _areaId;
              final color = PlannerStyle.colorFromHex(a.color);
              return ChoiceChip(
                selected: selected,
                showCheckmark: false,
                avatar: Icon(PlannerStyle.iconFor(a.icon), size: 16, color: selected ? Colors.white : color),
                label: Text(a.name),
                labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600),
                selectedColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                onSelected: (_) => setState(() => _areaId = a.id),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
        HoursInput(
          controller: _hours,
          label: 'Extra hours',
          presets: const [1, 2, 4, 6, 8],
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 16),
        PlannerTextArea(
          controller: _title,
          label: 'What for? (optional)',
          hint: 'e.g. Weekend backtesting session on GBPUSD',
          minLines: 2,
          maxLines: 6,
        ),
        const SizedBox(height: 20),
        if (area != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: semantic.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BeforeAfter(label: 'Week capacity', before: capBefore, after: capAfter),
                const SizedBox(height: 6),
                _BeforeAfter(label: '${area.name} budget', before: budgetBefore, after: budgetAfter),
                const SizedBox(height: 8),
                Text(
                  'Shows in ${area.name}\'s task list as planned work — evaluate it and log time like any task. '
                  'Other areas\' budgets and your free time stay the same.',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: semantic.loss)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving || _pickableAreas.isEmpty ? null : _save,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _saving
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                : Text(_isEdit ? 'Save changes' : 'Add extra hours'),
          ),
        ),
      ],
    );
  }
}

class _BeforeAfter extends StatelessWidget {
  final String label;
  final double before;
  final double after;

  const _BeforeAfter({required this.label, required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        Text(PlannerStyle.hours(before), style: TextStyle(color: cs.onSurfaceVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward, size: 14, color: cs.onSurfaceVariant),
        ),
        Text(PlannerStyle.hours(after), style: TextStyle(fontWeight: FontWeight.w800, color: semantic.info)),
      ],
    );
  }
}
