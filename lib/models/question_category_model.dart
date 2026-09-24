class QuestionCategoryModel {
  final int id;
  final String name;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  QuestionCategoryModel({
    required this.id,
    required this.name,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory QuestionCategoryModel.fromJson(Map<String, dynamic> json) {
    return QuestionCategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      notes: json['notes'],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateJson() => {'name': name, 'notes': notes};

  Map<String, dynamic> toUpdateJson() => {'name': name, 'notes': notes};

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
