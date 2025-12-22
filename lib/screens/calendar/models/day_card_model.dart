// import 'package:tm_dashboard/enums/day_of_week_enum.dart';
//
// class DayCardModel {
//   final DateTime date;
//   final DayOfWeekEnum dayOfWeek;
//   final bool weekend;
//   final bool noWork;
//   final bool ended;
//
//   DayCardModel({
//     required this.date,
//     required this.dayOfWeek,
//     this.weekend = false,
//     this.noWork = false,
//     this.ended = false,
//   });
//
//   DayCardModel copyWith({bool? weekend, bool? noWork, bool? ended}) {
//     return DayCardModel(
//       date: date,
//       dayOfWeek: dayOfWeek,
//       weekend: weekend ?? this.weekend,
//       noWork: noWork ?? this.noWork,
//       ended: ended ?? this.ended,
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     // todo: the day of week has a wrong value in the initialization
//     'dayOfWeek': date.weekday,
//     'weekend': weekend,
//     'noWork': noWork,
//     'ended': ended,
//   };
// }
