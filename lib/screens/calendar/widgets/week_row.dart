import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/calendar_state.dart';
import '../../../models/day_model.dart';
import 'day_edit_dialog.dart';

class WeekRow extends StatelessWidget {
  final List<DayModel> row;
  final int placeholders;

  const WeekRow({required this.row, this.placeholders = 0, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        if (i < placeholders) return const Expanded(child: SizedBox());

        final dayIndex = i - placeholders;

        if (dayIndex >= row.length) return const Expanded(child: SizedBox());

        final DayModel day = row[dayIndex];
        final today = DateTime.now();
        final isToday =
            day.date.year == today.year &&
            day.date.month == today.month &&
            day.date.day == today.day;

        Color backgroundColor;

        if (isToday) {
          backgroundColor = Colors.deepPurple.shade100;
        } else if (day.noWork) {
          backgroundColor = Colors.grey.shade300;
        } else if (day.ended) {
          backgroundColor = Colors.grey.shade200;
        } else if (day.weekend) {
          backgroundColor = Colors.orange.shade100;
        } else {
          backgroundColor = Colors.grey.shade100;
        }

        return Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {},
            onExit: (_) {},
            child: GestureDetector(
              onTap: () => _openDayDialog(context, day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: Text(
                          day.date.day.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            // color: day.noWork
                            //     ? Colors.black54
                            //     : day.ended
                            //     ? Colors.black45
                            //     : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    // const SizedBox(height: 4),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     if (isWeekend)
                    //       Container(
                    //         width: 6,
                    //         height: 6,
                    //         margin: const EdgeInsets.symmetric(horizontal: 1),
                    //         decoration: BoxDecoration(
                    //           color: Colors.orange.shade400,
                    //           shape: BoxShape.circle,
                    //         ),
                    //       ),
                    //     if (day.noWork)
                    //       Container(
                    //         width: 6,
                    //         height: 6,
                    //         margin: const EdgeInsets.symmetric(horizontal: 1),
                    //         decoration: BoxDecoration(
                    //           color: Colors.grey.shade600,
                    //           shape: BoxShape.circle,
                    //         ),
                    //       ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _openDayDialog(BuildContext context, DayModel day) {
    final cubit = context.read<CalendarCubit>();
    showDialog(
      context: context,
      builder: (_) => DayEditDialog(day: day, cubit: cubit),
    );
  }
}
