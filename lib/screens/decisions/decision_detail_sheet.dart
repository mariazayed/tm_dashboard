import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/decision_model.dart';
import '../../widgets/md_editor_field.dart';

/// Shows a decision's full details as a bottom sheet over whatever screen
/// is currently visible -- used so a decision's title, or a "Reconsiders
/// #N" reference to another decision, can be opened without leaving the
/// Decisions list (or the add/edit sheet). Tapping a "Reconsiders" chip
/// inside the sheet pushes another one on top rather than replacing this
/// one, so following a chain of related decisions is just a stack of
/// sheets the user can dismiss back through.
Future<void> showDecisionDetailSheet(
  BuildContext context,
  DecisionModel decision,
  List<DecisionModel> allDecisions, {
  VoidCallback? onEdit,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DecisionDetailSheet(
      decision: decision,
      allDecisions: allDecisions,
      onEdit: onEdit,
    ),
  );
}

class _DecisionDetailSheet extends StatelessWidget {
  final DecisionModel decision;
  final List<DecisionModel> allDecisions;
  final VoidCallback? onEdit;

  const _DecisionDetailSheet({
    required this.decision,
    required this.allDecisions,
    this.onEdit,
  });

  DecisionModel? get _related {
    final num = decision.relatedDecisionNumber;
    if (num == null) return null;
    for (final d in allDecisions) {
      if (d.decisionNumber == num) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    final related = _related;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (decision.decisionNumber != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(right: 8, top: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${decision.decisionNumber}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      decision.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                dateFmt.format(decision.decisionDate),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tag(decision.category.label, const Color(0xFF6366F1)),
                  _tag(decision.status.label, Colors.grey.shade700),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'What was decided',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              buildMarkdownPreview(context, decision.description),
              if (decision.reasoning != null && decision.reasoning!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Why',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                buildMarkdownPreview(context, decision.reasoning!),
              ],
              if (related != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Reconsiders',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => showDecisionDetailSheet(context, related, allDecisions),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.north_east, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '#${related.decisionNumber} — ${related.title}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (decision.relatedDecisionNumber != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Reconsiders decision #${decision.relatedDecisionNumber} (not loaded)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                ),
              ],
              if (decision.notes != null && decision.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Notes',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(decision.notes!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ),
              ],
              if (onEdit != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit!();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Edit'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
