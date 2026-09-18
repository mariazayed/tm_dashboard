import 'package:flutter/material.dart';

import '../../enums/capital_reason_enum.dart';
import '../../models/capital_model.dart';
import '../../theme/app_theme.dart';

class CapitalList extends StatelessWidget {
  final List<CapitalModel> capitals;

  const CapitalList({super.key, required this.capitals});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: capitals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 18),
      itemBuilder: (_, i) {
        final c = capitals[i];
        final semantic = context.semanticColors;

        late Color primaryColor;
        late IconData icon;
        late String label;

        switch (c.reason) {
          case CapitalReasonEnum.DEPOSIT:
            primaryColor = semantic.profit;
            icon = Icons.south_west_rounded;
            label = "Deposit";
            break;

          case CapitalReasonEnum.WITHDRAW:
            primaryColor = semantic.loss;
            icon = Icons.north_east_rounded;
            label = "Withdraw";
            break;

          case CapitalReasonEnum.PROFIT:
            primaryColor = semantic.info;
            icon = Icons.trending_up_rounded;
            label = "Profit";
            break;

          case CapitalReasonEnum.LOSS:
            primaryColor = semantic.orange;
            icon = Icons.trending_down_rounded;
            label = "Loss";
            break;
        }

        return Card(
          elevation: 2,
          shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: primaryColor.withOpacity(0.06), // subtle flat tint
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.12),
                      ),
                      child: Icon(icon, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 14),

                    /// Reason + Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.formatter.format(c.dateTime),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),

                    /// Amount Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        c.amount.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                /// Notes
                if (c.notes != null && c.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Text(
                      c.notes!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
