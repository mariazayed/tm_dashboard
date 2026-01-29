import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'header.dart';
import 'month_grid.dart';
import 'week_labels.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Header(),
            const SizedBox(height: 8),
            const WeekLabels(),
            const SizedBox(height: 8),
            Expanded(child: MonthGrid()),
          ],
        ),
      ),
    );
  }
}
