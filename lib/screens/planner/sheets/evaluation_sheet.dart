import 'package:flutter/material.dart';

import '../../../enums/plan_item_status_enum.dart';
import '../../../models/planner_models.dart';
import '../../../services/planner_service.dart';
import '../../../theme/app_theme.dart';
import '../planner_style.dart';
import '../widgets/planner_widgets.dart';

/// Evaluate one weekly task or monthly objective: outcome, 1-5 score,
/// actual hours and notes. Shared by both -- the caller supplies how to
/// save via [onSubmit].
class EvaluationSheet extends StatefulWidget {
  final String title;
  final FocusAreaModel focusArea;
  final double estimatedHours;
  final PlanItemStatusEnum status;
  final int? score;
  final double? actualHours;
  final String? evaluationNotes;
  // Monthly objectives: hours already credited by linked weekly tasks,
  // offered as a one-tap suggestion for "actual hours".
  final double? suggestedActualHours;
  final Future<void> Function(PlannerEvaluation evaluation) onSubmit;

  const EvaluationSheet({
    super.key,
    required this.title,
    required this.focusArea,
    required this.estimatedHours,
    required this.status,
    this.score,
    this.actualHours,
    this.evaluationNotes,
    this.suggestedActualHours,
    required this.onSubmit,
  });

  @override
  State<EvaluationSheet> createState() => _EvaluationSheetState();
}

class _EvaluationSheetState extends State<EvaluationSheet> {
  late PlanItemStatusEnum _status;
  int? _score;
  late final TextEditingController _actual;
  late final TextEditingController _notes;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = widget.status == PlanItemStatusEnum.PLANNED ? PlanItemStatusEnum.DONE : widget.status;
    _score = widget.score;
    final a = widget.actualHours;
    _actual = TextEditingController(
      text: a == null ? '' : (a == a.roundToDouble() ? a.toInt().toString() : a.toString()),
    );
    _notes = TextEditingController(text: widget.evaluationNotes ?? '');
  }

  @override
  void dispose() {
    _actual.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save({bool reset = false}) async {
    final actualText = _actual.text.trim().replaceAll(',', '.');
    final evaluation = reset
        ? const PlannerEvaluation(status: PlanItemStatusEnum.PLANNED)
        : PlannerEvaluation(
            status: _status,
            score: _score,
            actualHours: actualText.isEmpty ? null : double.tryParse(actualText),
            evaluationNotes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(evaluation);
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
    const outcomes = [PlanItemStatusEnum.DONE, PlanItemStatusEnum.PARTIAL, PlanItemStatusEnum.MISSED];

    return PlannerSheet(
      children: [
        const SheetHeader(title: 'Evaluate'),
        Row(
          children: [
            AreaIconBadge(area: widget.focusArea, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(
                    '${widget.focusArea.name} · planned ${PlannerStyle.hours(widget.estimatedHours)}',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Outcome', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        const SizedBox(height: 10),
        Row(
          children: outcomes.map((o) {
            final selected = _status == o;
            final color = StatusPill.colorOf(context, o);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: o == outcomes.last ? 0 : 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _status = o),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? color : color.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: selected ? 1 : 0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(StatusPill.iconOf(o), color: selected ? Colors.white : color),
                        const SizedBox(height: 4),
                        Text(
                          o.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('How well did it go?', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        ScoreStars(score: _score, size: 34, onChanged: (v) => setState(() => _score = v)),
        const SizedBox(height: 20),
        HoursInput(
          controller: _actual,
          label: 'Actual time spent',
          presets: <double>{
            widget.estimatedHours,
            if (widget.suggestedActualHours != null &&
                widget.suggestedActualHours! > 0 &&
                widget.suggestedActualHours != widget.estimatedHours)
              widget.suggestedActualHours!,
            0,
          }.toList(),
        ),
        if (widget.suggestedActualHours != null && widget.suggestedActualHours! > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Linked weekly tasks have credited ${PlannerStyle.hours(widget.suggestedActualHours!)} so far.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 16),
        PlannerTextArea(
          controller: _notes,
          label: 'What happened? Lessons? (optional)',
          hint: 'What went well, what got in the way, what to change next time…',
          minLines: 4,
          maxLines: 12,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: context.semanticColors.loss)),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            if (widget.status.isEvaluated)
              TextButton.icon(
                onPressed: _saving ? null : () => _save(reset: true),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                child: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                      )
                    : const Text('Save evaluation'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
