import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tm_dashboard/screens/calendar/widgets/week_row.dart';

import '../../../bloc/calendar_state.dart';
import '../../../models/day_model.dart';
import '../calendar_screen.dart';
import 'dashed_border.dart';

class MonthGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        final days = state.days.values.toList();
        final firstWeekday = DateTime(state.currentMonth.year, state.currentMonth.month, 1).weekday;
        final placeholderCount = (firstWeekday - 1) % 7;

        final rows = <List<DayModel>>[];
        for (var i = 0; i < days.length; i += 7) {
          rows.add(days.sublist(i, i + 7 > days.length ? days.length : i + 7));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Column(
            key: ValueKey(state.currentMonth),
            children: List.generate(rows.length, (rowIndex) {
              final row = rows[rowIndex];
              final isLastRow = rowIndex == rows.length - 1;

              Widget weekRow = WeekRow(
                row: row,
                placeholders: rowIndex == 0 ? placeholderCount : 0,
              );

              if (isLastRow) {
                // Wrap last row in dashed border
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
