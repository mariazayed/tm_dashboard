import 'package:intl/intl.dart';
import 'package:tm_dashboard/enums/day_of_week_enum.dart';
import 'package:tm_dashboard/enums/score_enum.dart';

class DayModel {
  final int id;
  final DateTime date;
  final DayOfWeekEnum dayOfWeek;
  final ScoreEnum? psychologyRate;
  final bool weekend;
  final bool noWork;
  final bool ended;
  final bool isImportant;
  final String notes;
  bool exists;

  DayModel({
    required this.id,
    required this.date,
    required this.dayOfWeek,
    this.psychologyRate,
    this.weekend = false,
    this.noWork = false,
    this.ended = false,
    this.isImportant = false,
    this.notes = '',
    this.exists = false,
  });

  DayModel copyWith({
    bool? weekend,
    bool? noWork,
    bool? ended,
    bool? isImportant,
    String? notes,
    ScoreEnum? psychologyRate,
  }) {
    return DayModel(
      id: id,
      dayOfWeek: dayOfWeek,
      psychologyRate: psychologyRate ?? this.psychologyRate,
      date: date,
      weekend: weekend ?? this.weekend,
      noWork: noWork ?? this.noWork,
      ended: ended ?? this.ended,
      isImportant: isImportant ?? this.isImportant,
      notes: notes ?? this.notes,
      exists: exists,
    );
  }

  factory DayModel.fromJson(Map<String, dynamic> json) {
    return DayModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      dayOfWeek: DayOfWeekEnum.fromValue(json['dayOfWeek']),
      psychologyRate: json['psychologyRate'] != null
          ? ScoreEnum.fromValue(json['psychologyRate'])
          : null,
      weekend: json['weekend'] ?? false,
      noWork: json['noWork'] ?? false,
      ended: json['ended'] ?? false,
      isImportant: json['isImportant'] ?? false,
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': formatter.format(date),
      'dayOfWeek': dayOfWeek,
      'weekend': weekend,
      'psychologyRate': psychologyRate,
      'noWork': noWork,
      'ended': ended,
      'isImportant': isImportant,
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
    'psychologyRate': psychologyRate?.value,
    'date': formatter.format(date),
    'weekend': weekend,
    'noWork': noWork,
    'ended': ended,
    'isImportant': isImportant,
    'notes': notes,
  };
}
