import 'package:intl/intl.dart';

import '../enums/decision_category_enum.dart';
import '../enums/decision_status_enum.dart';

class DecisionModel {
  final int id;

  // Server-assigned (continues the log's 1, 2, 3... sequence) -- never sent
  // back on create/update, see toCreateJson/toUpdateJson.
  final int? decisionNumber;

  final DateTime decisionDate;
  final String title;
  final DecisionCategoryEnum category;
  final DecisionStatusEnum status;

  // Markdown text, edited via MdEditorField.
  final String description;
  final String? reasoning;

  final int? relatedDecisionNumber;
  final String? notes;

  DecisionModel({
    required this.id,
    this.decisionNumber,
    required this.decisionDate,
    required this.title,
    required this.category,
    required this.status,
    required this.description,
    this.reasoning,
    this.relatedDecisionNumber,
    this.notes,
  });

  static final DateFormat _formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  factory DecisionModel.fromJson(Map<String, dynamic> json) {
    return DecisionModel(
      id: json['id'],
      decisionNumber: json['decisionNumber'],
      decisionDate: DateTime.parse(json['decisionDate']),
      title: json['title'] ?? '',
      category: DecisionCategoryEnum.fromValue(json['category']),
      status: DecisionStatusEnum.fromValue(json['status']),
      description: json['description'] ?? '',
      reasoning: json['reasoning'],
      relatedDecisionNumber: json['relatedDecisionNumber'],
      notes: json['notes'],
    );
  }

  // decisionNumber is deliberately omitted -- the server assigns it (see
  // DecisionService.create); NewDecisionRequest has no field for it.
  Map<String, dynamic> toCreateJson() => {
    'decisionDate': _formatter.format(decisionDate),
    'title': title,
    'category': category.value,
    'description': description,
    'reasoning': reasoning,
    'relatedDecisionNumber': relatedDecisionNumber,
    'notes': notes,
  };

  // decisionNumber is immutable once assigned -- UpdateDecisionRequest has
  // no field for it, so it's left out here too.
  Map<String, dynamic> toUpdateJson() => {
    'decisionDate': _formatter.format(decisionDate),
    'title': title,
    'category': category.value,
    'status': status.value,
    'description': description,
    'reasoning': reasoning,
    'relatedDecisionNumber': relatedDecisionNumber,
    'notes': notes,
  };

  DecisionModel copyWith({
    DateTime? decisionDate,
    String? title,
    DecisionCategoryEnum? category,
    DecisionStatusEnum? status,
    String? description,
    String? reasoning,
    int? relatedDecisionNumber,
    bool clearRelatedDecisionNumber = false,
    String? notes,
  }) {
    return DecisionModel(
      id: id,
      decisionNumber: decisionNumber,
      decisionDate: decisionDate ?? this.decisionDate,
      title: title ?? this.title,
      category: category ?? this.category,
      status: status ?? this.status,
      description: description ?? this.description,
      reasoning: reasoning ?? this.reasoning,
      relatedDecisionNumber: clearRelatedDecisionNumber
          ? null
          : (relatedDecisionNumber ?? this.relatedDecisionNumber),
      notes: notes ?? this.notes,
    );
  }
}
