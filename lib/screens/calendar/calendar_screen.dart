import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:tm_dashboard/widgets/page_back_button.dart';

import 'header.dart';
import 'month_grid.dart';
import 'week_labels.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const PageBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Calendar'),
      ),
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
