import 'package:flutter/material.dart';

import '../../../models/planner_models.dart';
import '../../../theme/app_theme.dart';
import '../planner_style.dart';
import '../widgets/planner_widgets.dart';

/// Log the actual time spent on a weekly task -- any time during the week,
/// not only at evaluation. Quick "+15m / +30m / +1h / +2h" chips add to the
/// current total, or type an exact value. Actual time may go past the
/// estimate; the sheet shows by how much instead of stopping you.
///
/// [onSubmit] receives the new total, or null to clear it.
class LogTimeSheet extends StatefulWidget {
  final WeeklyTaskModel task;
  final Future<void> Function(double? actualHours) onSubmit;

  const LogTimeSheet({super.key, required this.task, required this.onSubmit});

  @override
  State<LogTimeSheet> createState() => _LogTimeSheetState();
}

class _LogTimeSheetState extends State<LogTimeSheet> {
  late final TextEditingController _total;
  bool _saving = false;
  String? _error;

  static const _quickAdds = [0.25, 0.5, 1.0, 2.0];

  @override
  void initState() {
    super.initState();
    _total = TextEditingController(text: _fmt(widget.task.actualHours ?? 0));
  }

  @override
  void dispose() {
    _total.dispose();
    super.dispose();
  }

  static String _fmt(double h) {
    if (h == h.roundToDouble()) return h.toInt().toString();
    return h.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  double get _value => double.tryParse(_total.text.trim().replaceAll(',', '.')) ?? 0;

  void _add(double h) {
    final next = (_value + h).clamp(0, 999).toDouble();
    setState(() => _total.text = _fmt(next));
  }

  Future<void> _save({bool clear = false}) async {
    if (!clear && _value < 0) {
      setState(() => _error = 'Time can\'t be negative');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(clear ? null : _value);
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
    final t = widget.task;
    final est = t.estimatedHours;
    final value = _value;
    final diff = value - est;

    final String verdict;
    final Color verdictColor;
    if (est <= 0) {
      verdict = 'No estimate was set for this task.';
      verdictColor = cs.onSurfaceVariant;
    } else if (diff > 1e-9) {
      verdict = '${PlannerStyle.hours(diff)} over the ${PlannerStyle.hours(est)} estimate '
          '(${PlannerStyle.pct(value / est * 100)}).';
      verdictColor = semantic.warning;
    } else if (diff.abs() < 1e-9) {
      verdict = 'Exactly on estimate.';
      verdictColor = semantic.profit;
    } else {
      verdict = '${PlannerStyle.hours(-diff)} left of the ${PlannerStyle.hours(est)} estimate.';
      verdictColor = cs.onSurfaceVariant;
    }

    return PlannerSheet(
      children: [
        const SheetHeader(title: 'Log time'),
        Row(
          children: [
            AreaIconBadge(area: t.focusArea, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Big live readout
        Center(
          child: Column(
            children: [
              Text(
                PlannerStyle.hours(value),
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: diff > 1e-9 && est > 0 ? semantic.warning : null,
                ),
              ),
              const SizedBox(height: 4),
              Text('of ${PlannerStyle.hours(est)} estimated', style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TimeTrackBar(estimated: est, actual: value, height: 10),
        const SizedBox(height: 8),
        Text(verdict, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: verdictColor, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),

        Text('Add', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final h in _quickAdds) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _add(h),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(h < 1 ? '+${(h * 60).round()}m' : '+${PlannerStyle.hours(h)}'),
                ),
              ),
              if (h != _quickAdds.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: value <= 0 ? null : () => _add(-0.25),
              icon: const Icon(Icons.remove, size: 16),
              label: const Text('15m'),
            ),
            const Spacer(),
            if (est > 0)
              TextButton(
                onPressed: () => setState(() => _total.text = _fmt(est)),
                child: const Text('Set to estimate'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _total,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Total time spent', suffixText: 'hours'),
          onChanged: (_) => setState(() {}),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: semantic.loss)),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            if (t.actualHours != null)
              TextButton.icon(
                onPressed: _saving ? null : () => _save(clear: true),
                icon: const Icon(Icons.timer_off_outlined, size: 18),
                label: const Text('Clear'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                child: _saving
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                    : const Text('Save time'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
