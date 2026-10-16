class ReminderNoteCategoryModel {
  const ReminderNoteCategoryModel({required this.id, required this.name});

  final int id;
  final String name;

  factory ReminderNoteCategoryModel.fromJson(Map<String, dynamic> json) =>
      ReminderNoteCategoryModel(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
      );
}
