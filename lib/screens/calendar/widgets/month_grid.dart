import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tm_dashboard/screens/calendar/widgets/week_row.dart';

import '../../../bloc/calendar_state.dart';
import '../../../models/day_model.dart';
import '../../../services/day_service.dart';
import 'dashed_border.dart';

class MonthGrid extends StatelessWidget {
  final DayService _dayService = DayService();
  Map<int, DayModel> daysMap = {};

  MonthGrid({super.key});

  Future<void> _loadData() async {
    List<DayModel> daysList = await _dayService.getAll();
    for (var dayObj in daysList) {
      daysMap[dayObj.date.day] = dayObj;
    }

    print(daysMap);
  }

  @override
  Widget build(BuildContext context) {
    _loadData();

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

        for (var i = 0; i < days.length; i += 1) {
          print(days[i].date.day);
          print(daysMap);
          if (daysMap[days[i].date.day] != null) {
            days[i] = daysMap[days[i].date.day]!;
          }
        }

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
