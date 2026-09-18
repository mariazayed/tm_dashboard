import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/decision_category_enum.dart';
import '../../enums/decision_status_enum.dart';
import '../../models/decision_model.dart';
import '../../theme/app_theme.dart';
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

  /// See `decision_card.dart`'s `_categoryColor` for the same mapping and
  /// the judgment call on PERSONAL/OTHERS (no exact cyan/orchid theme
  /// equivalent exists, so they fall back to the closest categorical
  /// accents, `info`/`violet`).
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

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: colorScheme.outlineVariant,
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
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorScheme.outlineVariant),
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
                  Expanded(
                    child: Text(
                      decision.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
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
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateFmt.format(decision.decisionDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
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
                  _tag(decision.category.label, categoryColor),
                  _tag(decision.status.label, statusColor),
                ],
              ),
              const SizedBox(height: 18),
              _section(
                context,
                title: 'What was decided',
                child: buildMarkdownPreview(
                  context,
                  decision.description,
                  baseStyle: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ),
              if (decision.reasoning != null &&
                  decision.reasoning!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _section(
                  context,
                  title: 'Why',
                  tinted: true,
                  child: buildMarkdownPreview(
                    context,
                    decision.reasoning!,
                    baseStyle: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
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
                    color: colorScheme.onSurfaceVariant,
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
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.north_east,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '#${related.decisionNumber} - ${related.title}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface,
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
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Text(
                        'Decision #$decisionNumber (not loaded)',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
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
                  context,
                  title: 'Notes',
                  warning: true,
                  child: Text(
                    decision.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: semantic.warning,
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

  Widget _section(
    BuildContext context, {
    required String title,
    required Widget child,
    bool tinted = false,
    bool warning = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final background = warning
        ? semantic.warning.withValues(alpha: 0.12)
        : tinted
        ? colorScheme.surfaceContainerLow
        : colorScheme.surface;
    final border = warning
        ? semantic.warning.withValues(alpha: 0.4)
        : colorScheme.outlineVariant;

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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurfaceVariant,
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
