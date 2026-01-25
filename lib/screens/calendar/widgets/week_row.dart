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
        Color textColor = const Color(0xFF1F2937);
        double opacity = 1.0;
        // final bool isWeekend = day.date.weekday == 6 || day.date.weekday == 7;

        if (isToday) {
          backgroundColor = Theme.of(context).colorScheme.primaryContainer;
          textColor = Theme.of(context).colorScheme.onPrimaryContainer;
        } else if (day.noWork) {
          backgroundColor = const Color(0xFFF3F4F6);
          textColor = Colors.grey.shade400;
          opacity = 0.6;
        } else if (day.ended) {
          backgroundColor = Colors.white;
          textColor = Colors.grey.shade500;
          opacity = 0.8;
        } else if (day.weekend) {
          backgroundColor = const Color(0xFFFFF7ED);
          textColor = const Color(0xFFC2410C);
        } else {
          backgroundColor = Colors.white;
        }

        return Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _openDayDialog(context, day),
              child: Opacity(
                opacity: opacity,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isToday
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.5)
                          : Colors.grey.shade200,
                      width: isToday ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.date.day.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        if (day.noWork)
                          const Icon(Icons.block, size: 14, color: Colors.grey)
                        else if (day.ended)
                          Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: Colors.green.shade300,
                          )
                        else if (day.weekend)
                          Icon(
                            Icons.weekend_outlined,
                            size: 14,
                            color: Colors.orange.shade300,
                          ),
                      ],
                    ),
                  ),
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
