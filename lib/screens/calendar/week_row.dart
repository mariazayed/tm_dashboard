import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/day_model.dart';
import 'calendar_state.dart';
import 'day_edit_dialog.dart';

class WeekRow extends StatelessWidget {
  final List<DayModel> row;
  final int placeholders;

  const WeekRow({required this.row, this.placeholders = 0, super.key});

  /// Emoji for each exact psychology score
  String _emojiForScore(int value) {
    switch (value) {
      case 1:
        return "😡";
      case 2:
        return "😖";
      case 3:
        return "😞";
      case 4:
        return "😕";
      case 5:
        return "😐";
      case 6:
        return "🙂";
      case 7:
        return "😌";
      case 8:
        return "😎";
      case 9:
        return "🚀";
      case 10:
        return "🧠🔥";
      default:
        return "";
    }
  }

  /// Background color for each psychology score
  Color? _backgroundForScore(int value) {
    switch (value) {
      case 1:
        return const Color(0xFFFFCDD2); // 😡 strong red
      case 2:
        return const Color(0xFFFFE0E0); // 😖 soft red
      case 3:
        return const Color(0xFFFFCCBC); // 😞 orange-red
      case 4:
        return const Color(0xFFFFE0B2); // 😕 light orange
      case 5:
        return const Color(0xFFE0E0E0); // 😐 neutral grey
      case 6:
        return const Color(0xFFC8E6C9); // 🙂 light green
      case 7:
        return const Color(0xFFA5D6A7); // 😌 calm green
      case 8:
        return const Color(0xFFB3E5FC); // 😎 cool blue
      case 9:
        return const Color(0xFFD1C4E9); // 🚀 purple
      case 10:
        return const Color(0xFFFFF59D); // 🧠🔥 gold
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        if (i < placeholders) return const Expanded(child: SizedBox());

        final dayIndex = i - placeholders;
        if (dayIndex >= row.length) {
          return const Expanded(child: SizedBox());
        }

        final DayModel day = row[dayIndex];
        final today = DateTime.now();
        final isToday =
            day.date.year == today.year &&
            day.date.month == today.month &&
            day.date.day == today.day;

        Color backgroundColor;
        Color textColor = const Color(0xFF1F2937);
        double opacity = 1.0;

        // Mark days with notes with a different background
        // if (day.notes.isNotEmpty) {
        //   backgroundColor = Colors.yellow.shade100; // background for notes
        // } else

        /// ✅ Psychology background (added)
        if (day.psychologyRate != null) {
          backgroundColor =
              _backgroundForScore(day.psychologyRate!.value) ?? Colors.white;
        } else if (isToday) {
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

        final List<Widget> statusIcons = [
          if (day.noWork) const Icon(Icons.block, size: 14, color: Colors.grey),

          if (day.ended)
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: Colors.green.shade300,
            ),

          if (day.weekend)
            Icon(
              Icons.weekend_outlined,
              size: 14,
              color: Colors.orange.shade300,
            ),

          if (day.notes.isNotEmpty)
            Icon(Icons.note_add, size: 14, color: Colors.blue.shade300),

          if (day.exists)
            Icon(Icons.hdr_strong, size: 14, color: Colors.purple.shade200),

          /// ✅ Psychology Emoji
          if (day.psychologyRate != null)
            Text(
              _emojiForScore(day.psychologyRate!.value),
              style: const TextStyle(fontSize: 14),
            ),
        ];

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
                        if (statusIcons.isNotEmpty)
                          SizedBox(
                            height: 16,
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              children: statusIcons,
                            ),
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
