class ReminderNoteModel {
  final int id;
  final String text;
  final int? categoryId;
  final String? categoryName;

  ReminderNoteModel({
    required this.id,
    required this.text,
    this.categoryId,
    this.categoryName,
  });

  factory ReminderNoteModel.fromJson(Map<String, dynamic> json) {
    return ReminderNoteModel(
      id: json['id'],
      text: json['text'],
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryName: json['categoryName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    if (categoryId != null) 'categoryId': categoryId,
  };
}
