import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tm_dashboard/enums/day_of_week_enum.dart';
import 'package:tm_dashboard/services/day_service.dart';

import '../models/day_model.dart';

class CalendarState {
  final DateTime currentMonth;
  final Map<int, DayModel> days;

  CalendarState({required this.currentMonth, required this.days});

  CalendarState copyWith({
    DateTime? currentMonth,
    Map<int, DayModel>? days,
  }) {
    return CalendarState(
      currentMonth: currentMonth ?? this.currentMonth,
      days: days ?? this.days,
    );
  }
}

class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit()
    : super(
        CalendarState(
          currentMonth: DateTime(DateTime.now().year, DateTime.now().month),
          days: {},
        ),
      ) {
    _generateDays();
  }

  Future<void> _generateDays() async {
    final lastDay = DateTime(
      state.currentMonth.year,
      state.currentMonth.month + 1,
      0,
    ).day;

    final Map<int, DayModel> map = {};

    // 1. Generate default days
    for (int dayNumber = 1; dayNumber <= lastDay; dayNumber++) {
      final date = DateTime(
        state.currentMonth.year,
        state.currentMonth.month,
        dayNumber,
      );

      map[dayNumber] = DayModel(
        id: -1,
        date: date,
        dayOfWeek: DayOfWeekEnum.fromValue(date.weekday),
      );
    }

    // 2. Fetch existing days from API
    try {
      final apiDays = await DayService().getAll();

      // 3. Override generated days with API data
      for (final apiDay in apiDays) {
        final localDate = apiDay.date.toLocal();

        final normalizedDate = DateTime(
          localDate.year,
          localDate.month,
          localDate.day,
        );

        // Only fill days belonging to current month
        if (normalizedDate.month == state.currentMonth.month &&
            normalizedDate.year == state.currentMonth.year) {
          final dayNumber = localDate.day;
          map[dayNumber] = apiDay;
          map[dayNumber]?.exists = true;
        }
      }
    } catch (e) {
      print("Error fetching days: $e");
    }

    emit(state.copyWith(days: map));
  }

  Future<void> nextMonth() async {
    final newMonth = DateTime(
      state.currentMonth.year,
      state.currentMonth.month + 1,
    );
    emit(state.copyWith(currentMonth: newMonth));
    await _generateDays();
  }

  Future<void> previousMonth() async {
    final newMonth = DateTime(
      state.currentMonth.year,
      state.currentMonth.month - 1,
    );
    emit(state.copyWith(currentMonth: newMonth));
    await _generateDays();
  }

  void updateDay(DayModel day) {
    final newDays = {...state.days};
    newDays[day.date.day] = day;
    emit(state.copyWith(days: newDays));
  }
}
