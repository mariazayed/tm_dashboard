import 'package:tm_dashboard/enums/day_of_week_enum.dart';

class DayModel {
  final DayOfWeekEnum dayOfWeek;
  final bool weekend;
  final bool noWork;
  final bool isEnded;

  DayModel({
    required this.dayOfWeek,
    this.weekend = false,
    this.noWork = false,
    this.isEnded = false,
  });

  DayModel copyWith({bool? weekend, bool? noWork, bool? isEnded}) {
    return DayModel(
      dayOfWeek: dayOfWeek,
      weekend: weekend ?? this.weekend,
      noWork: noWork ?? this.noWork,
      isEnded: isEnded ?? this.isEnded,
    );
  }

  factory DayModel.fromJson(Map<String, dynamic> json) {
    return DayModel(
      dayOfWeek: json['dayOfWeek'],
      weekend: json['weekend'],
      noWork: json['noWork'],
      isEnded: json['isEnded'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'weekend': weekend,
      'noWork': noWork,
      'isEnded': isEnded,
    };
  }

  Map<String, dynamic> toJson() => {
    'dayOfWeek': dayOfWeek,
    'weekend': weekend,
    'noWork': noWork,
    'isEnded': isEnded,
  };
}
