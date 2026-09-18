import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/decision_category_enum.dart';
import '../../enums/decision_status_enum.dart';
import '../../models/decision_model.dart';
import '../../theme/app_theme.dart';
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

  /// Categorical accent per decision category. TRADING/INVESTING/SYSTEM/
  /// LEARNING map cleanly onto existing semantic/ColorScheme roles;
  /// PERSONAL (originally a cyan not represented anywhere else in the
  /// theme) is mapped to the closest existing categorical accent,
  /// `semanticColors.info`, and OTHERS (a light violet) to
  /// `semanticColors.violet` -- both a judgment call, not an exact color
  /// match, since the theme has no dedicated cyan/orchid accent.
  Color _categoryColor(BuildContext context) {
    final semantic = context.semanticColors;
    switch (decision.category) {
      case DecisionCategoryEnum.TRADING:
        return semantic.warning;
      case DecisionCategoryEnum.INVESTING:
        return semantic.profit;
      case DecisionCategoryEnum.PERSONAL:
        return semantic.info;
      case DecisionCategoryEnum.SYSTEM:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case DecisionCategoryEnum.LEARNING:
        return Theme.of(context).colorScheme.primary;
      case DecisionCategoryEnum.OTHERS:
        return semantic.violet;
    }
  }

  Color _statusColor(BuildContext context) {
    final semantic = context.semanticColors;
    switch (decision.status) {
      case DecisionStatusEnum.ACTIVE:
        return semantic.profit;
      case DecisionStatusEnum.SUPERSEDED:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case DecisionStatusEnum.REVERSED:
        return semantic.loss;
      case DecisionStatusEnum.COMPLETED:
        return Theme.of(context).colorScheme.primary;
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
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final categoryColor = _categoryColor(context);
    final statusColor = _statusColor(context);
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
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.035),
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
                color: categoryColor,
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
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Text(
                              '#${decision.decisionNumber}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        _pill(decision.category.label, categoryColor),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFmt.format(decision.decisionDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        _pill(decision.status.label, statusColor),
                        PopupMenuButton<String>(
                          tooltip: 'Decision actions',
                          icon: Icon(
                            Icons.more_horiz,
                            color: colorScheme.onSurfaceVariant,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _previewText(decision.description),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
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
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Why',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _previewText(decision.reasoning!),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
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
                                context,
                                'Reconsiders #${related.decisionNumber} - ${related.title}',
                              ),
                            ),
                          ),
                          ...missingRelatedNumbers.map(
                            (decisionNumber) =>
                                _chip(context, 'Reconsiders #$decisionNumber'),
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
                          color: semantic.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: semantic.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          decision.notes!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: semantic.warning,
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

  Widget _chip(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _previewText(String text) {
    return text
        .replaceAll(RegExp(r'[`*_#>-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
