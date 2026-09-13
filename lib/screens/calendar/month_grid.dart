import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tm_dashboard/screens/calendar/week_row.dart';

import 'calendar_state.dart';
import '../../models/day_model.dart';
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

      // Denominator for the day-cell heatmap tint: the single largest
      // absolute net P&L across this month's days, so shading reflects
      // each day's size relative to the month rather than a fixed number.
      double maxAbsPnl = 0;
      for (final dayTrades in state.tradesByDay.values) {
        final netPnl = dayTrades.fold(0.0, (sum, t) => sum + t.profit);
        if (netPnl.abs() > maxAbsPnl) maxAbsPnl = netPnl.abs();
      }

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
                  tradesByDay: state.tradesByDay,
                  maxAbsPnl: maxAbsPnl,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _LegendHeatSwatch(colors: [
                          Color(0xFFEFF8F0),
                          Color(0xFFC8E6C9),
                          Color(0xFF86D18C),
                        ]),
                        const SizedBox(width: 6),
                        _LegendHeatSwatch(colors: [
                          Color(0xFFFDF1F0),
                          Color(0xFFFFCDD2),
                          Color(0xFFE57373),
                        ]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Day shading + accent bar scale with that day\'s net P&L (green = profit, red = loss); tap a day for the full trades overview',
                          ),
                        ),
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

/// Three small swatches (light -> strong) illustrating one arm of the
/// day-cell heatmap ramp in the legend.
class _LegendHeatSwatch extends StatelessWidget {
  final List<Color> colors;

  const _LegendHeatSwatch({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors
          .map(
            (c) => Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade200),
              ),
            ),
          )
          .toList(),
    );
  }
}
