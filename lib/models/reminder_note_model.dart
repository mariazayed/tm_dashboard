import 'package:tm_dashboard/enums/trade_direction_enum.dart';
import 'package:tm_dashboard/models/asset_model.dart';

class ReminderNoteModel {
  final String text;

  ReminderNoteModel({
    required this.text,
  });

  factory ReminderNoteModel.fromJson(Map<String, dynamic> json) {
    return ReminderNoteModel(
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
  };
}
