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

  final List<int> relatedDecisionNumbers;
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
    List<int>? relatedDecisionNumbers,
    this.notes,
  }) : relatedDecisionNumbers = List.unmodifiable(
         relatedDecisionNumbers ?? const [],
       );

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
      relatedDecisionNumbers: _relatedDecisionNumbersFromJson(json),
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
    'relatedDecisionNumbers': relatedDecisionNumbers,
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
    'relatedDecisionNumbers': relatedDecisionNumbers,
    'notes': notes,
  };

  DecisionModel copyWith({
    DateTime? decisionDate,
    String? title,
    DecisionCategoryEnum? category,
    DecisionStatusEnum? status,
    String? description,
    String? reasoning,
    List<int>? relatedDecisionNumbers,
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
      relatedDecisionNumbers:
          relatedDecisionNumbers ?? this.relatedDecisionNumbers,
      notes: notes ?? this.notes,
    );
  }

  static List<int> _relatedDecisionNumbersFromJson(Map<String, dynamic> json) {
    final rawList = json['relatedDecisionNumbers'];
    if (rawList is List) {
      return rawList.whereType<num>().map((value) => value.toInt()).toList();
    }

    final legacy = json['relatedDecisionNumber'];
    if (legacy is num) {
      return [legacy.toInt()];
    }

    return const [];
  }
}
