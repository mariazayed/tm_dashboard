import 'package:flutter/cupertino.dart';
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
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
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
          child: Column(
            key: ValueKey(state.currentMonth),
            children: List.generate(rows.length, (rowIndex) {
              final List<DayModel> row = rows[rowIndex];
              final bool isLastRow = rowIndex == rows.length - 1;

              Widget weekRow = WeekRow(
                row: row,
                placeholders: rowIndex == 0 ? placeholderCount : 0,
              );

              if (isLastRow) {
                weekRow = DashedBorder(child: weekRow);
              }

              return weekRow;
            }),
          ),
        );
      },
    );
  }
}
