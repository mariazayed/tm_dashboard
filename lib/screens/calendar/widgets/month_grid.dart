import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tm_dashboard/screens/calendar/widgets/week_row.dart';

import '../../../bloc/calendar_state.dart';
import '../../../models/day_model.dart';
import '../../../services/day_service.dart';
import 'dashed_border.dart';

class MonthGrid extends StatefulWidget {
  const MonthGrid({super.key});

  @override
  State<MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<MonthGrid> {
  final DayService _dayService = DayService();
  final Map<int, DayModel> daysMap = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final daysList = await _dayService.getAll();

    for (var dayObj in daysList) {
      daysMap[dayObj.date.day] = dayObj;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        List<DayModel> days = state.days.values.toList();

        final firstWeekday = DateTime(
          state.currentMonth.year,
          state.currentMonth.month,
          1,
        ).weekday;

        final placeholderCount = (firstWeekday - 1) % 7;

        // Merge loaded data into bloc days
        for (var i = 0; i < days.length; i++) {
          final loadedDay = daysMap[days[i].date.day];
          if (loadedDay != null) {
            loadedDay.exists = true;
            days[i] = loadedDay;
          }
        }

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
