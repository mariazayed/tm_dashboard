import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tm_dashboard/screens/calendar/widgets/header.dart';
import 'package:tm_dashboard/screens/calendar/widgets/week_labels.dart';

import 'widgets/month_grid.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
    );
  }
}
