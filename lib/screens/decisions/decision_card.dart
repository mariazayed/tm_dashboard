import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/decision_category_enum.dart';
import '../../enums/decision_status_enum.dart';
import '../../models/decision_model.dart';
import '../../widgets/md_editor_field.dart';
import 'decision_detail_sheet.dart';

class DecisionCard extends StatelessWidget {
  final DecisionModel decision;

  // Full list, needed so a "Reconsiders #N" reference (and the detail
  // sheet's own chain of references) can resolve to the referenced
  // decision and show it inline.
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (decision.decisionNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${decision.decisionNumber}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _categoryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  decision.category.label,
                  style: TextStyle(color: _categoryColor, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  decision.status.label,
                  style: TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.w600),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      showDecisionDetailSheet(context, decision, allDecisions, onEdit: onEdit);
                      break;
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'active':
                      onSetStatus?.call(DecisionStatusEnum.ACTIVE);
                      break;
                    case 'superseded':
                      onSetStatus?.call(DecisionStatusEnum.SUPERSEDED);
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
                  const PopupMenuItem(value: 'view', child: Text('View details')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (decision.status != DecisionStatusEnum.ACTIVE)
                    const PopupMenuItem(value: 'active', child: Text('Mark active')),
                  if (decision.status != DecisionStatusEnum.SUPERSEDED)
                    const PopupMenuItem(value: 'superseded', child: Text('Mark superseded')),
                  if (decision.status != DecisionStatusEnum.REVERSED)
                    const PopupMenuItem(value: 'reversed', child: Text('Mark reversed')),
                  if (decision.status != DecisionStatusEnum.COMPLETED)
                    const PopupMenuItem(value: 'completed', child: Text('Mark completed')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title is clickable -- opens the full decision inline as a
          // bottom sheet instead of navigating away from this list.
          InkWell(
            onTap: () => showDecisionDetailSheet(context, decision, allDecisions, onEdit: onEdit),
            child: Text(
              decision.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateFmt.format(decision.decisionDate),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 10),
          buildMarkdownPreview(
            context,
            decision.description,
            baseStyle: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
          ),
          if (decision.reasoning != null && decision.reasoning!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Why:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 2),
            buildMarkdownPreview(
              context,
              decision.reasoning!,
              baseStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic, height: 1.4),
            ),
          ],
          if (decision.relatedDecisionNumber != null) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: related == null
                  ? null
                  : () => showDecisionDetailSheet(context, related, allDecisions),
              child: _chip(
                related != null
                    ? 'Reconsiders #${related.decisionNumber} — ${related.title}'
                    : 'Reconsiders #${decision.relatedDecisionNumber}',
              ),
            ),
          ],
          if (decision.notes != null && decision.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                decision.notes!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
    );
  }
}
