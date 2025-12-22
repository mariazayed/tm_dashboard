import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:math';

// ====================
// Models
// ====================
class DayModel {
  final DateTime date;
  final bool isDone;
  final bool isSkipDay;
  final bool isEnded;
  final double progress;
  final IconData? icon;

  DayModel({
    required this.date,
    this.isDone = false,
    this.isSkipDay = false,
    this.isEnded = false,
    this.progress = 0.0,
    this.icon,
  });

  DayModel copyWith({
    bool? isDone,
    bool? isSkipDay,
    bool? isEnded,
    double? progress,
    IconData? icon,
  }) {
    return DayModel(
      date: date,
      isDone: isDone ?? this.isDone,
      isSkipDay: isSkipDay ?? this.isSkipDay,
      isEnded: isEnded ?? this.isEnded,
      progress: progress ?? this.progress,
      icon: icon ?? this.icon,
    );
  }
}

// ====================
// BLoC
// ====================
class CalendarState {
  final DateTime currentMonth;
  final Map<DateTime, DayModel> days;

  CalendarState({required this.currentMonth, required this.days});

  CalendarState copyWith({DateTime? currentMonth, Map<DateTime, DayModel>? days}) {
    return CalendarState(
      currentMonth: currentMonth ?? this.currentMonth,
      days: days ?? this.days,
    );
  }
}

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit()
      : super(CalendarState(
    currentMonth: DateTime(DateTime.now().year, DateTime.now().month),
    days: {},
  )) {
    _generateDays();
  }

  void _generateDays() {
    final firstDay = DateTime(state.currentMonth.year, state.currentMonth.month, 1);
    final lastDay = DateTime(state.currentMonth.year, state.currentMonth.month + 1, 0);
    final today = DateTime.now();

    Map<DateTime, DayModel> map = {};
    for (var i = 0; i < lastDay.day; i++) {
      final day = DateTime(state.currentMonth.year, state.currentMonth.month, i + 1);
      map[day] = DayModel(
        date: day,
        isEnded: day.isBefore(DateTime(today.year, today.month, today.day)),
      );
    }
    emit(state.copyWith(days: map));
  }

  void nextMonth() {
    final newMonth = DateTime(state.currentMonth.year, state.currentMonth.month + 1);
    emit(state.copyWith(currentMonth: newMonth));
    _generateDays();
  }

  void previousMonth() {
    final newMonth = DateTime(state.currentMonth.year, state.currentMonth.month - 1);
    emit(state.copyWith(currentMonth: newMonth));
    _generateDays();
  }

  void updateDay(DayModel day) {
    final newDays = {...state.days};
    newDays[day.date] = day;
    emit(state.copyWith(days: newDays));
  }
}

// ====================
// Main
// ====================
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CalendarCubit(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Modern Habit Tracker Calendar',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const CalendarScreen(),
      ),
    );
  }
}

// ====================
// Calendar Screen
// ====================
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Tracker Calendar')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const _Header(),
            const SizedBox(height: 8),
            const _WeekLabels(),
            const SizedBox(height: 8),
            Expanded(child: _MonthGrid()),
          ],
        ),
      ),
    );
  }
}

// ====================
// Header
// ====================
class _Header extends StatelessWidget {
  const _Header({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => context.read<CalendarCubit>().previousMonth(),
            ),
            Text(
              DateFormat.yMMMM().format(state.currentMonth),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => context.read<CalendarCubit>().nextMonth(),
            ),
          ],
        );
      },
    );
  }
}

// ====================
// Week Labels
// ====================
class _WeekLabels extends StatelessWidget {
  const _WeekLabels({super.key});
  @override
  Widget build(BuildContext context) {
    const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Row(
      children: labels
          .map((e) => Expanded(
        child: Center(
          child: Text(
            e,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ))
          .toList(),
    );
  }
}

// ====================
// Month Grid
// ====================
class _MonthGrid extends StatelessWidget {
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

              Widget weekRow = _WeekRow(
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

// ====================
// Dashed Border Widget
// ====================
class DashedBorder extends StatelessWidget {
  final Widget child;
  const DashedBorder({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: CustomPaint(
        painter: _DashedRectPainter(),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final paint = Paint()
      ..color = Colors.deepPurple
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(min(x + dashWidth, size.width), 0), paint);
      canvas.drawLine(Offset(x, size.height), Offset(min(x + dashWidth, size.width), size.height), paint);
      x += dashWidth + dashSpace;
    }

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, min(y + dashWidth, size.height)), paint);
      canvas.drawLine(Offset(size.width, y), Offset(size.width, min(y + dashWidth, size.height)), paint);
      y += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ====================
// Week Row
// ====================
class _WeekRow extends StatelessWidget {
  final List<DayModel> row;
  final int placeholders;
  const _WeekRow({required this.row, this.placeholders = 0, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        if (i < placeholders) return const Expanded(child: SizedBox());
        final dayIndex = i - placeholders;
        if (dayIndex >= row.length) return const Expanded(child: SizedBox());
        final day = row[dayIndex];
        final today = DateTime.now();
        final isToday = day.date.year == today.year &&
            day.date.month == today.month &&
            day.date.day == today.day;
        final isWeekend =
            day.date.weekday == DateTime.saturday || day.date.weekday == DateTime.sunday;

        Color backgroundColor;
        if (day.isSkipDay) {
          backgroundColor = Colors.grey.shade300;
        } else if (isToday) {
          backgroundColor = Colors.deepPurple.shade100;
        } else if (day.isEnded) {
          backgroundColor = isWeekend ? Colors.orange.shade100.withOpacity(0.4) : Colors.grey.shade200;
        } else if (day.isDone) {
          backgroundColor = Colors.green.shade200;
        } else if (isWeekend) {
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
                      child: CustomPaint(
                        painter: _ProgressRingPainter(day.progress),
                        child: Center(
                          child: Text(
                            day.date.day.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: day.isSkipDay
                                  ? Colors.black54
                                  : day.isEnded
                                  ? Colors.black45
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isWeekend)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (day.isSkipDay)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (day.icon != null) Icon(day.icon, size: 16),
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

// ====================
// Progress Ring Painter
// ====================
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  _ProgressRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 4.0;
    final rect = Offset.zero & size;
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final foregroundPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, 2 * pi, false, backgroundPaint);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ====================
// Day Edit Dialog
// ====================
class DayEditDialog extends StatefulWidget {
  final DayModel day;
  final CalendarCubit cubit;
  const DayEditDialog({super.key, required this.day, required this.cubit});

  @override
  State<DayEditDialog> createState() => _DayEditDialogState();
}

class _DayEditDialogState extends State<DayEditDialog> {
  late bool isDone;
  late double progress;
  late bool isSkipDay;
  IconData? icon;

  @override
  void initState() {
    super.initState();
    isDone = widget.day.isDone;
    progress = widget.day.progress;
    icon = widget.day.icon;
    isSkipDay = widget.day.isSkipDay;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Day ${widget.day.date.day}"),
      content: SizedBox(
        width: 300,
        height: 250,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Done:"),
                Switch(value: isDone, onChanged: (v) => setState(() => isDone = v)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Skip Day:"),
                Checkbox(value: isSkipDay, onChanged: (v) => setState(() => isSkipDay = v ?? false)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Progress:"),
                Slider(
                  value: progress,
                  onChanged: (v) => setState(() => progress = v),
                  divisions: 10,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Icon:"),
                DropdownButton<IconData>(
                  value: icon,
                  hint: const Text("Select"),
                  items: const [
                    DropdownMenuItem(child: Icon(Icons.star), value: Icons.star),
                    DropdownMenuItem(child: Icon(Icons.favorite), value: Icons.favorite),
                    DropdownMenuItem(child: Icon(Icons.check), value: Icons.check),
                  ],
                  onChanged: (v) => setState(() => icon = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final updated = widget.day.copyWith(
                    isDone: isDone, progress: progress, icon: icon, isSkipDay: isSkipDay);
                widget.cubit.updateDay(updated);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
