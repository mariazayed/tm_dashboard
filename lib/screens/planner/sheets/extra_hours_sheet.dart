import 'package:flutter/material.dart';

import '../../../models/planner_models.dart';
import '../../../services/planner_service.dart';
import '../../../theme/app_theme.dart';
import '../planner_style.dart';
import '../widgets/planner_widgets.dart';

/// Manages a week's extra working hours. Each entry is either general time
/// (raises total capacity, so every Focus Area's budget grows by its max %)
/// or dedicated to one Focus Area (added straight to that area's budget).
/// Changes save immediately; [onChanged] hands the refreshed week back so
/// the Week view updates live behind the sheet.
class ExtraHoursSheet extends StatefulWidget {
  final String weekLabel;
  final DateTime weekStart;
  final WeekPlanModel plan;
  final List<FocusAreaModel> areas;
  final ValueChanged<WeekPlanModel> onChanged;

  const ExtraHoursSheet({
    super.key,
    required this.weekLabel,
    required this.weekStart,
    required this.plan,
    required this.areas,
    required this.onChanged,
  });

  @override
  State<ExtraHoursSheet> createState() => _ExtraHoursSheetState();
}

class _ExtraHoursSheetState extends State<ExtraHoursSheet> {
  late WeekPlanModel _plan;
  final _hours = TextEditingController();
  final _note = TextEditingController();
  int? _areaId; // null = general
  WeekExtraModel? _editing;
  bool _saving = false;
  final Set<int> _busy = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
  }

  @override
  void dispose() {
    _hours.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _value => double.tryParse(_hours.text.trim().replaceAll(',', '.')) ?? 0;

  List<FocusAreaModel> get _pickableAreas {
    final list = widget.areas.where((a) => !a.archived).toList();
    final editingArea = _editing?.focusArea;
    if (editingArea != null && !list.any((a) => a.id == editingArea.id)) list.add(editingArea);
    return list;
  }

  void _apply(WeekPlanModel plan) {
    setState(() => _plan = plan);
    widget.onChanged(plan);
  }

  void _startEdit(WeekExtraModel e) {
    setState(() {
      _editing = e;
      _hours.text = e.hours == e.hours.roundToDouble() ? e.hours.toInt().toString() : e.hours.toString();
      _note.text = e.note ?? '';
      _areaId = e.focusArea?.id;
      _error = null;
    });
  }

  void _resetForm() {
    setState(() {
      _editing = null;
      _hours.clear();
      _note.clear();
      _areaId = null;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_value <= 0) {
      setState(() => _error = 'Enter how many extra hours');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final plan = _editing == null
          ? await PlannerService.addExtra(widget.weekStart, hours: _value, focusAreaId: _areaId, note: _note.text.trim())
          : await PlannerService.updateExtra(_editing!.id, hours: _value, focusAreaId: _areaId, note: _note.text.trim());
      if (!mounted) return;
      _apply(plan);
      _resetForm();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(WeekExtraModel e) async {
    setState(() => _busy.add(e.id));
    try {
      final plan = await PlannerService.deleteExtra(e.id);
      if (!mounted) return;
      _apply(plan);
      if (_editing?.id == e.id) _resetForm();
    } catch (err) {
      if (mounted) setState(() => _error = err.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy.remove(e.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final selectedArea = _pickableAreas.where((a) => a.id == _areaId).firstOrNull;

    return PlannerSheet(
      children: [
        SheetHeader(title: 'Extra working hours', subtitle: widget.weekLabel),

        // ---- capacity summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [semantic.info.withValues(alpha: 0.12), cs.primary.withValues(alpha: 0.06)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _SumCell(label: 'Regular', value: PlannerStyle.hours(_plan.baseHours)),
              _op('+'),
              _SumCell(label: 'Extra', value: PlannerStyle.hours(_plan.extraHours), color: semantic.info),
              _op('='),
              _SumCell(label: 'This week', value: PlannerStyle.hours(_plan.capacityHours), bold: true),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ---- existing entries
        if (_plan.extras.isNotEmpty) ...[
          Text('This week', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
          const SizedBox(height: 10),
          ..._plan.extras.map((e) => _ExtraTile(
                extra: e,
                selected: _editing?.id == e.id,
                busy: _busy.contains(e.id),
                onEdit: () => _startEdit(e),
                onDelete: () => _delete(e),
              )),
          const SizedBox(height: 16),
        ],

        // ---- add / edit form
        PlannerPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_editing == null ? Icons.add_circle_outline : Icons.edit_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    _editing == null ? 'Add extra hours' : 'Edit entry',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              HoursInput(
                controller: _hours,
                label: 'Hours',
                presets: const [1, 2, 4, 6, 8],
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 18),
              Text('Where do these hours go?', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    selected: _areaId == null,
                    showCheckmark: false,
                    avatar: Icon(Icons.all_inclusive, size: 16, color: _areaId == null ? cs.onPrimary : cs.primary),
                    label: const Text('General'),
                    labelStyle: TextStyle(color: _areaId == null ? cs.onPrimary : null, fontWeight: FontWeight.w600),
                    selectedColor: cs.primary,
                    onSelected: (_) => setState(() => _areaId = null),
                  ),
                  ..._pickableAreas.map((a) {
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
                  }),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      selectedArea == null
                          ? 'General time raises the whole week, so every Focus Area\'s budget grows by its max %.'
                          : 'Adds ${PlannerStyle.hours(_value)} straight to ${selectedArea.name}\'s budget, on top of its ${PlannerStyle.pct(selectedArea.maxPercent)} share.',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PlannerTextArea(
                controller: _note,
                label: 'Why? (optional)',
                hint: 'e.g. Weekend backtesting session on GBPUSD',
                minLines: 2,
                maxLines: 6,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: semantic.loss)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_editing != null)
                    TextButton(onPressed: _saving ? null : _resetForm, child: const Text('Cancel edit')),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                        : Icon(_editing == null ? Icons.add : Icons.check, size: 18),
                    label: Text(_editing == null ? 'Add' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ),
      ],
    );
  }

  Widget _op(String s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(s, style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class _SumCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  const _SumCell({required this.label, required this.value, this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: bold ? 22 : 18, fontWeight: FontWeight.w800, color: color),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ExtraTile extends StatelessWidget {
  final WeekExtraModel extra;
  final bool selected;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExtraTile({
    required this.extra,
    required this.selected,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final area = extra.focusArea;
    final color = area != null ? PlannerStyle.colorFromHex(area.color) : semantic.info;

    return Opacity(
      opacity: busy ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : cs.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            area != null
                ? AreaIconBadge(area: area, size: 36)
                : Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: semantic.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.all_inclusive, size: 18, color: semantic.info),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '+${PlannerStyle.hours(extra.hours)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          area?.name ?? 'General',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if ((extra.note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(extra.note!, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
              onPressed: busy ? null : onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              onPressed: busy ? null : onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
