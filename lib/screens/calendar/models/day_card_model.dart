import 'package:tm_dashboard/enums/day_of_week_enum.dart';

class DayCardModel {
  final DateTime date;
  final DayOfWeekEnum dayOfWeek;
  final bool weekend;
  final bool noWork;
  final bool isEnded;

  DayCardModel({
    required this.date,
    required this.dayOfWeek,
    this.weekend = false,
    this.noWork = false,
    this.isEnded = false,
  });

  DayCardModel copyWith({
    bool? weekend,
    bool? noWork,
    bool? isEnded,
  }) {
    return DayCardModel(
      date: date,
      dayOfWeek: dayOfWeek,
      weekend: weekend ?? this.weekend,
      noWork: noWork ?? this.noWork,
      isEnded: isEnded ?? this.isEnded,
    );
  }
}