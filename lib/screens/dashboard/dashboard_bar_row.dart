import 'package:flutter/material.dart';

/// A single labeled, proportional horizontal bar -- used by the dashboard's
/// "PnL by Strategy", "PnL by Session" and "Mistake Frequency" cards.
///
/// Chosen over a vertical fl_chart bar chart because the categories here
/// (strategy names, mistake tags) are free-text and variable-length:
/// rotated or truncated x-axis labels are far less legible than a
/// left-aligned label sitting right next to its own bar and value, and
/// every row is self-labeled so no separate legend is needed.
class DashboardBarRow extends StatelessWidget {
  final String label;
  final String valueText;

  /// Bar fill relative to the row group's max, 0..1.
  final double fraction;
  final Color color;

  const DashboardBarRow({
    super.key,
    required this.label,
    required this.valueText,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                valueText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
