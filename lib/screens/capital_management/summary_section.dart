import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'summary_card.dart';
import 'summary_data.dart';

class SummarySection extends StatelessWidget {
  final SummaryData daily;
  final SummaryData weekly;
  final SummaryData monthly;
  final bool wide;

  const SummarySection({
    required this.daily,
    required this.weekly,
    required this.monthly,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      SummaryCard(title: 'Today', data: daily),
      SummaryCard(title: 'This Week', data: weekly),
      SummaryCard(title: 'This Month', data: monthly),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: SummaryCard(title: 'Today', data: daily)),
          const VerticalDivider(width: 24),
          Expanded(child: SummaryCard(title: 'Week', data: weekly)),
          const VerticalDivider(width: 24),
          Expanded(child: SummaryCard(title: 'Month', data: monthly)),
        ],
      ),
    );
  }
}

