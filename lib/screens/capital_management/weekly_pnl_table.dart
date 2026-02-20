import 'package:flutter/material.dart';

class WeeklyPnlTable extends StatelessWidget {
  final double profit;
  final double loss;

  const WeeklyPnlTable({super.key, required this.profit, required this.loss});

  @override
  Widget build(BuildContext context) {
    final net = profit + loss;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Title
          Text(
            "Weekly Breakdown",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 20),

          /// Table Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("Type", style: TextStyle(fontWeight: FontWeight.w600)),
              Text("Amount", style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),

          const Divider(height: 28),

          /// Profit Row
          _buildRow(
            label: "Profit",
            value: profit,
            color: Colors.green.shade500,
          ),

          const SizedBox(height: 14),

          /// Loss Row
          _buildRow(label: "Loss", value: loss, color: Colors.red.shade400),

          const Divider(height: 28),

          /// Net Row
          _buildRow(
            label: "Net",
            value: net,
            color: net >= 0 ? Colors.green.shade600 : Colors.red.shade600,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required double value,
    required Color color,
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
