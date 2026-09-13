import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/decision_category_enum.dart';
import '../../enums/decision_status_enum.dart';
import '../../models/decision_model.dart';
import '../../widgets/md_editor_field.dart';

/// Shows a decision's full details as a bottom sheet over whatever screen
/// is currently visible -- used so a decision's title, or "Reconsiders
/// #N" references to other decisions, can be opened without leaving the
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

  List<DecisionModel> get _relatedDecisions {
    return decision.relatedDecisionNumbers
        .map((decisionNumber) {
          for (final d in allDecisions) {
            if (d.decisionNumber == decisionNumber) {
              return d;
            }
          }
          return null;
        })
        .whereType<DecisionModel>()
        .toList();
  }

  Color get _categoryColor {
    switch (decision.category) {
      case DecisionCategoryEnum.TRADING:
        return const Color(0xFFF59E0B);
      case DecisionCategoryEnum.INVESTING:
        return const Color(0xFF22C55E);
      case DecisionCategoryEnum.PERSONAL:
        return const Color(0xFF06B6D4);
      case DecisionCategoryEnum.SYSTEM:
        return const Color(0xFF6B7280);
      case DecisionCategoryEnum.LEARNING:
        return const Color(0xFF818CF8);
      case DecisionCategoryEnum.OTHERS:
        return const Color(0xFFA78BFA);
    }
  }

  Color get _statusColor {
    switch (decision.status) {
      case DecisionStatusEnum.ACTIVE:
        return const Color(0xFF22C55E);
      case DecisionStatusEnum.SUPERSEDED:
        return const Color(0xFF9CA3AF);
      case DecisionStatusEnum.REVERSED:
        return const Color(0xFFEF4444);
      case DecisionStatusEnum.COMPLETED:
        return const Color(0xFF818CF8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    final relatedDecisions = _relatedDecisions;
    final loadedRelatedNumbers = relatedDecisions
        .map((d) => d.decisionNumber)
        .toSet();
    final missingRelatedNumbers = decision.relatedDecisionNumbers
        .where(
          (decisionNumber) => !loadedRelatedNumbers.contains(decisionNumber),
        )
        .toList();

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
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (decision.decisionNumber != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 8, top: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        '#${decision.decisionNumber}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      decision.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        height: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateFmt.format(decision.decisionDate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tag(decision.category.label, _categoryColor),
                  _tag(decision.status.label, _statusColor),
                ],
              ),
              const SizedBox(height: 18),
              _section(
                title: 'What was decided',
                child: buildMarkdownPreview(
                  context,
                  decision.description,
                  baseStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                    height: 1.5,
                  ),
                ),
              ),
              if (decision.reasoning != null &&
                  decision.reasoning!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _section(
                  title: 'Why',
                  tinted: true,
                  child: buildMarkdownPreview(
                    context,
                    decision.reasoning!,
                    baseStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              if (decision.relatedDecisionNumbers.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Reconsiders',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                ...relatedDecisions.map(
                  (related) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => showDecisionDetailSheet(
                        context,
                        related,
                        allDecisions,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.north_east,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '#${related.decisionNumber} - ${related.title}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ...missingRelatedNumbers.map(
                  (decisionNumber) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        'Decision #$decisionNumber (not loaded)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (decision.notes != null &&
                  decision.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _section(
                  title: 'Notes',
                  warning: true,
                  child: Text(
                    decision.notes!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF92400E),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              if (onEdit != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () {
                    Navigator.pop(context);
                    onEdit!();
                  },
                  label: const Padding(
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

  Widget _section({
    required String title,
    required Widget child,
    bool tinted = false,
    bool warning = false,
  }) {
    final background = warning
        ? const Color(0xFFFFFBEB)
        : tinted
        ? const Color(0xFFF8FAFC)
        : Colors.white;
    final border = warning ? const Color(0xFFFDE68A) : const Color(0xFFE5E7EB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
