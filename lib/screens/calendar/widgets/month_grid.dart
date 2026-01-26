import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tm_dashboard/screens/calendar/widgets/week_row.dart';

import '../../../bloc/calendar_state.dart';
import '../../../models/day_model.dart';
import 'dashed_border.dart';

class MonthGrid extends StatefulWidget {
  const MonthGrid({super.key});

  @override
  State<MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<MonthGrid> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(builder: (context, state) {
      List<DayModel> days = state.days.values.toList();

      final firstWeekday = DateTime(
        state.currentMonth.year,
        state.currentMonth.month,
        1,
      ).weekday;

      final placeholderCount = (firstWeekday - 1) % 7;

      final rows = <List<DayModel>>[];
      int currentDayIndex = 0;

      // First row
      int firstRowCapacity = 7 - placeholderCount;
      if (currentDayIndex < days.length) {
        int end = currentDayIndex + firstRowCapacity;
        if (end > days.length) end = days.length;
        rows.add(days.sublist(currentDayIndex, end));
        currentDayIndex = end;
      }

      // Subsequent rows
      while (currentDayIndex < days.length) {
        int end = currentDayIndex + 7;
        if (end > days.length) end = days.length;
        rows.add(days.sublist(currentDayIndex, end));
        currentDayIndex = end;
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: SingleChildScrollView(
          key: ValueKey(state.currentMonth),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              // Existing Week Rows
              ...List.generate(rows.length, (rowIndex) {
                final List<DayModel> row = rows[rowIndex];
                return WeekRow(
                  row: row,
                  placeholders: rowIndex == 0 ? placeholderCount : 0,
                );
              }),

              // Icon legend at the bottom
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legend:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline, size: 18, color: Colors.green.shade300),
                        const SizedBox(width: 10),
                        Text('Completed'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.block, size: 18, color: Colors.grey),
                        const SizedBox(width: 10),
                        Text('No work'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.weekend_outlined, size: 18, color: Colors.orange.shade300),
                        const SizedBox(width: 10),
                        Text('Weekend'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.note_add, size: 18, color: Colors.blue.shade300),
                        const SizedBox(width: 10),
                        Text('Notes'),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.hdr_strong, size: 18, color: Colors.purple.shade200),
                        const SizedBox(width: 10),
                        Text('Day exists'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

