import 'package:flutter/material.dart';

import '../../../models/planner_models.dart';
import '../../../services/planner_service.dart';
import '../../../theme/app_theme.dart';
import '../planner_style.dart';
import '../widgets/planner_widgets.dart';

/// Create / edit a Focus Area: name, max % of weekly time, color, icon.
class FocusAreaSheet extends StatefulWidget {
  final FocusAreaModel? existing;
  // Sum of the other areas' max % -- shown as context, never enforced.
  final double otherAreasPercent;

  const FocusAreaSheet({super.key, this.existing, this.otherAreasPercent = 0});

  @override
  State<FocusAreaSheet> createState() => _FocusAreaSheetState();
}

class _FocusAreaSheetState extends State<FocusAreaSheet> {
  late final TextEditingController _name;
  late double _max;
  late String _color;
  late String _icon;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _max = e?.maxPercent ?? 20;
    _color = e?.color ?? PlannerStyle.palette.first;
    _icon = e?.icon ?? PlannerStyle.icons.keys.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the Focus Area a name');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final data = {'name': name, 'maxPercent': _max, 'color': _color, 'icon': _icon};
    try {
      if (_isEdit) {
        await PlannerService.updateFocusArea(widget.existing!.id, data);
      } else {
        await PlannerService.createFocusArea(data);
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
    final color = PlannerStyle.colorFromHex(_color);
    final total = widget.otherAreasPercent + _max;
    final preview = FocusAreaModel(
      id: 0,
      name: _name.text.trim().isEmpty ? 'Focus Area' : _name.text.trim(),
      color: _color,
      icon: _icon,
      maxPercent: _max,
    );

    return PlannerSheet(
      children: [
        SheetHeader(title: _isEdit ? 'Edit Focus Area' : 'New Focus Area'),
        Row(
          children: [
            AreaIconBadge(area: preview, size: 52),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _name,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Backtesting'),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Max share of weekly time', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
            const Spacer(),
            Text(PlannerStyle.pct(_max), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(activeTrackColor: color, thumbColor: color),
          child: Slider(
            value: _max,
            min: 0,
            max: 100,
            divisions: 20,
            label: PlannerStyle.pct(_max),
            onChanged: (v) => setState(() => _max = v),
          ),
        ),
        Text(
          'All Focus Areas together: ${PlannerStyle.pct(total)}'
          '${total > 100 ? ' — that\'s fine, each max is a cap, not a reservation.' : ''}',
          style: TextStyle(fontSize: 12, color: total > 100 ? semantic.warning : cs.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Text('Color', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: PlannerStyle.palette.map((hex) {
            final c = PlannerStyle.colorFromHex(hex);
            final selected = hex == _color;
            return InkWell(
              customBorder: const CircleBorder(),
              onTap: () => setState(() => _color = hex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? cs.onSurface : Colors.transparent, width: 3),
                ),
                child: selected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('Icon', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlannerStyle.icons.entries.map((e) {
            final selected = e.key == _icon;
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _icon = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected ? color : color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(e.value, color: selected ? Colors.white : color),
              ),
            );
          }).toList(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: semantic.loss)),
        ],
        const SizedBox(height: 24),
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
                : Text(_isEdit ? 'Save changes' : 'Create Focus Area'),
          ),
        ),
      ],
    );
  }
}
