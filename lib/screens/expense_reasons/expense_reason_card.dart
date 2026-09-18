import 'package:flutter/material.dart';

import '../../models/expense_reason_model.dart';

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

  static const List<Color> _palette = [
    Color(0xFF818CF8), // indigo
    Color(0xFF22C55E), // green
    Color(0xFF3B82F6), // blue
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFF14B8A6), // teal
  ];

  Color get _color {
    final sum = reason.name.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[sum % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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
                    icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
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
