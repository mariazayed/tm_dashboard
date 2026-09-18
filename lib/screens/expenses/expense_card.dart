import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense_model.dart';
import '../../theme/app_theme.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  // True while a delete request for this expense is in flight (tracked by
  // the parent ExpensesScreen) -- same busy/spinner pattern as
  // AssetCard/GoalCard.
  final bool busy;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onEdit,
    this.onDelete,
    this.busy = false,
  });

  // Categorical palette used to color-code expense-reason badges by a hash
  // of the reason's name. `pink`/`teal` have no dedicated theme role, so
  // they stay as fixed accents in both light and dark mode.
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

  Color _reasonColor(BuildContext context) {
    final sum = expense.expenseReason.name.codeUnits.fold<int>(0, (a, b) => a + b);
    final palette = _palette(context);
    return palette[sum % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _reasonColor(context);
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final dateFmt = DateFormat('MMM d, yyyy');

    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          expense.expenseReason.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateFmt.format(expense.date),
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (expense.notes != null && expense.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      expense.notes!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '-\$${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: semantic.loss,
              ),
            ),
            busy
                ? const Padding(
                    padding: EdgeInsets.only(left: 4),
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
