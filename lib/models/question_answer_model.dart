import 'question_category_model.dart';

class QuestionAnswerModel {
  final int id;
  final String question;
  final String answer;
  final QuestionCategoryModel? category;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  QuestionAnswerModel({
    required this.id,
    required this.question,
    required this.answer,
    this.category,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory QuestionAnswerModel.fromJson(Map<String, dynamic> json) {
    return QuestionAnswerModel(
      id: json['id'],
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      category: json['category'] == null
          ? null
          : QuestionCategoryModel.fromJson(json['category']),
      notes: json['notes'],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'question': question,
    'answer': answer,
    'categoryId': category?.id,
    'notes': notes,
  };

  Map<String, dynamic> toUpdateJson() => {
    'question': question,
    'answer': answer,
    'categoryId': category?.id,
    'notes': notes,
  };

  QuestionAnswerModel copyWith({
    String? question,
    String? answer,
    QuestionCategoryModel? category,
    String? notes,
  }) {
    return QuestionAnswerModel(
      id: id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
