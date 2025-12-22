import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tm_dashboard/enums/day_of_week_enum.dart';

import '../screens/calendar/models/day_card_model.dart';

class CalendarState {
  final DateTime currentMonth;
  final Map<DateTime, DayCardModel> days;

  CalendarState({required this.currentMonth, required this.days});

  CalendarState copyWith({
    DateTime? currentMonth,
    Map<DateTime, DayCardModel>? days,
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

  void _generateDays() {
    final firstDay = DateTime(
      state.currentMonth.year,
      state.currentMonth.month,
      1,
    );
    final lastDay = DateTime(
      state.currentMonth.year,
      state.currentMonth.month + 1,
      0,
    );
    final today = DateTime.now();

    Map<DateTime, DayCardModel> map = {};
    for (var i = 0; i < lastDay.day; i++) {
      final day = DateTime(
        state.currentMonth.year,
        state.currentMonth.month,
        i + 1,
      );
      map[day] = DayCardModel(
        date: day,
        dayOfWeek: DayOfWeekEnum.fromValue(today.weekday),
        isEnded: day.isBefore(DateTime(today.year, today.month, today.day)),
      );
    }
    emit(state.copyWith(days: map));
  }

  void nextMonth() {
    final newMonth = DateTime(
      state.currentMonth.year,
      state.currentMonth.month + 1,
    );
    emit(state.copyWith(currentMonth: newMonth));
    _generateDays();
  }

  void previousMonth() {
    final newMonth = DateTime(
      state.currentMonth.year,
      state.currentMonth.month - 1,
    );
    emit(state.copyWith(currentMonth: newMonth));
    _generateDays();
  }

  void updateDay(DayCardModel day) {
    final newDays = {...state.days};
    newDays[day.date] = day;
    emit(state.copyWith(days: newDays));
  }
}
