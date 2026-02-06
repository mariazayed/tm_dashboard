class ReminderNoteModel {
  final int id;
  final String text;

  ReminderNoteModel({
    required this.id,
    required this.text,
  });

  factory ReminderNoteModel.fromJson(Map<String, dynamic> json) {
    return ReminderNoteModel(
      id: json['id'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
  };
}
