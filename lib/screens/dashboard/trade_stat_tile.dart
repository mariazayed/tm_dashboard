import 'package:flutter/material.dart';

/// A compact stat card for the dashboard's Trade Performance row (win rate,
/// profit factor, avg win/loss, current streak). Same visual language as
/// [CapitalStatCard] but takes a formatter instead of forcing every value
/// through `toStringAsFixed(2)`, since these values aren't all currency.
class TradeStatTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double numericValue;
  final String Function(double value) formatter;
  final VoidCallback? onTap;

  const TradeStatTile({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.numericValue,
    required this.formatter,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                formatter(numericValue),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
