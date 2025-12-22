import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tm_dashboard/screens/calendar/widgets/header.dart';
import 'package:tm_dashboard/screens/calendar/widgets/week_labels.dart';
import 'package:tm_dashboard/services/day_service.dart';

import 'widgets/month_grid.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DayService _dayService = DayService();

  @override
  void initState() {
    _dayService.getAll();
    super.initState();
  }

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
