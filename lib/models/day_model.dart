import 'package:intl/intl.dart';
import 'package:tm_dashboard/enums/day_of_week_enum.dart';

class DayModel {
  final int id;
  final DateTime date;
  final DayOfWeekEnum dayOfWeek;
  final bool weekend;
  final bool noWork;
  final bool ended;
  final String notes;
  bool exists;

  DayModel({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    this.weekend = false,
    this.noWork = false,
    this.ended = false,
    this.notes = '',
    this.exists = false,
  });

  DayModel copyWith({bool? weekend, bool? noWork, bool? ended, String? notes}) {
    return DayModel(
      id: id,
      dayOfWeek: dayOfWeek,
      date: date,
      weekend: weekend ?? this.weekend,
      noWork: noWork ?? this.noWork,
      ended: ended ?? this.ended,
      notes: notes ?? this.notes,
    );
  }

  factory DayModel.fromJson(Map<String, dynamic> json) {
    return DayModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      dayOfWeek: DayOfWeekEnum.fromValue(json['dayOfWeek']),
      weekend: json['weekend'] ?? false,
      noWork: json['noWork'] ?? false,
      ended: json['ended'] ?? false,
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': formatter.format(date),
      'dayOfWeek': dayOfWeek,
      'weekend': weekend,
      'noWork': noWork,
      'ended': ended,
      'notes': notes,
    };
  }

  // "yyyy-MM-dd HH:mm:ss.SSS"
  // DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
  DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  // Format the date
  //   String formattedDate = formatter.format(now);

  Map<String, dynamic> toJson() => {
    // todo: the day of week has a wrong value in the initialization
    'dayOfWeek': date.weekday,
    'date': formatter.format(date),
    'weekend': weekend,
    'noWork': noWork,
    'ended': ended,
    'notes': notes,
  };
}
