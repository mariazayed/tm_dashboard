import 'package:flutter/material.dart';

import '../../models/expense_reason_model.dart';
import '../../theme/app_theme.dart';

/// Same rounded-card look as AssetCard, simplified to a single-line lookup
/// row since ExpenseReason only carries a name.
class ExpenseReasonCard extends StatelessWidget {
  final ExpenseReasonModel reason;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  // True while a delete request for this reason is in flight (tracked by
  // the parent screen) -- swaps the "..." menu for a spinner, same pattern
  // as AssetCard/GoalCard's `busy`.
  final bool busy;

  const ExpenseReasonCard({
    super.key,
    required this.reason,
    this.onEdit,
    this.onDelete,
    this.busy = false,
  });

  // Categorical palette used to color-code reason icons by a hash of the
  // reason's name. `pink`/`teal` have no dedicated theme role, so they stay
  // as fixed accents in both light and dark mode.
  List<Color> _palette(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    return [
      colorScheme.primary, // indigo
      semantic.profit, // green
      semantic.info, // blue
      semantic.warning, // amber
      const Color(0xFFEC4899), // pink
      const Color(0xFF14B8A6), // teal
    ];
  }

  Color _color(BuildContext context) {
    final sum = reason.name.codeUnits.fold<int>(0, (a, b) => a + b);
    final palette = _palette(context);
    return palette[sum % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.receipt_long, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            busy
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: colorScheme.onSurfaceVariant),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
