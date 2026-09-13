import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/decision_category_enum.dart';
import '../../enums/decision_status_enum.dart';
import '../../models/decision_model.dart';
import '../../widgets/md_editor_field.dart';
import 'decision_detail_sheet.dart';

class DecisionCard extends StatelessWidget {
  final DecisionModel decision;

  // Full list, needed so "Reconsiders #N" references (and the detail
  // sheet's own chain of references) can resolve to referenced decisions
  // and show them inline.
  final List<DecisionModel> allDecisions;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<DecisionStatusEnum>? onSetStatus;

  const DecisionCard({
    super.key,
    required this.decision,
    required this.allDecisions,
    this.onEdit,
    this.onDelete,
    this.onSetStatus,
  });

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _categoryColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (decision.decisionNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
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
                        _pill(decision.category.label, _categoryColor),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFmt.format(decision.decisionDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        _pill(decision.status.label, _statusColor),
                        PopupMenuButton<String>(
                          tooltip: 'Decision actions',
                          icon: Icon(
                            Icons.more_horiz,
                            color: Colors.grey.shade500,
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'view':
                                showDecisionDetailSheet(
                                  context,
                                  decision,
                                  allDecisions,
                                  onEdit: onEdit,
                                );
                                break;
                              case 'edit':
                                onEdit?.call();
                                break;
                              case 'active':
                                onSetStatus?.call(DecisionStatusEnum.ACTIVE);
                                break;
                              case 'superseded':
                                onSetStatus?.call(
                                  DecisionStatusEnum.SUPERSEDED,
                                );
                                break;
                              case 'reversed':
                                onSetStatus?.call(DecisionStatusEnum.REVERSED);
                                break;
                              case 'completed':
                                onSetStatus?.call(DecisionStatusEnum.COMPLETED);
                                break;
                              case 'delete':
                                onDelete?.call();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('View details'),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            if (decision.status != DecisionStatusEnum.ACTIVE)
                              const PopupMenuItem(
                                value: 'active',
                                child: Text('Mark active'),
                              ),
                            if (decision.status !=
                                DecisionStatusEnum.SUPERSEDED)
                              const PopupMenuItem(
                                value: 'superseded',
                                child: Text('Mark superseded'),
                              ),
                            if (decision.status != DecisionStatusEnum.REVERSED)
                              const PopupMenuItem(
                                value: 'reversed',
                                child: Text('Mark reversed'),
                              ),
                            if (decision.status != DecisionStatusEnum.COMPLETED)
                              const PopupMenuItem(
                                value: 'completed',
                                child: Text('Mark completed'),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => showDecisionDetailSheet(
                        context,
                        decision,
                        allDecisions,
                        onEdit: onEdit,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          decision.title,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    buildMarkdownPreview(
                      context,
                      decision.description,
                      baseStyle: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        height: 1.45,
                      ),
                    ),
                    if (decision.reasoning != null &&
                        decision.reasoning!.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Why',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 3),
                            buildMarkdownPreview(
                              context,
                              decision.reasoning!,
                              baseStyle: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (decision.relatedDecisionNumbers.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...relatedDecisions.map(
                            (related) => InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => showDecisionDetailSheet(
                                context,
                                related,
                                allDecisions,
                              ),
                              child: _chip(
                                'Reconsiders #${related.decisionNumber} - ${related.title}',
                              ),
                            ),
                          ),
                          ...missingRelatedNumbers.map(
                            (decisionNumber) =>
                                _chip('Reconsiders #$decisionNumber'),
                          ),
                        ],
                      ),
                    ],
                    if (decision.notes != null &&
                        decision.notes!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          decision.notes!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF475569),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
