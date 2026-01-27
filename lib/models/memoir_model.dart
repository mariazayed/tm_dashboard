import 'package:intl/intl.dart';
import 'package:tm_dashboard/enums/day_of_week_enum.dart';

class MemoirModel {
  final int id;
  final DateTime date;
  final String title;
  final String description;

  MemoirModel({
    required this.id,
    required this.date,
    required this.title,
    required this.description,
  });

  MemoirModel copyWith() {
    return MemoirModel(
      id: id,
      date: date,
      title: title,
      description: description
    );
  }

  factory MemoirModel.fromJson(Map<String, dynamic> json) {
    return MemoirModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': formatter.format(date),
      'title': title,
      'description': description,
    };
  }

  // "yyyy-MM-dd HH:mm:ss.SSS"
  // DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
  DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  // Format the date
  //   String formattedDate = formatter.format(now);

  Map<String, dynamic> toJson() => {
    'date': formatter.format(date),
    'title': title,
    'description': description,
  };
}
