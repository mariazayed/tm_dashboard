import 'package:intl/intl.dart';

import '../enums/goal_category_enum.dart';
import '../enums/goal_status_enum.dart';

class GoalModel {
  final int id;
  final String title;
  final GoalCategoryEnum category;
  final GoalStatusEnum status;
  final double? targetValue;
  final DateTime startDate;
  final DateTime endDate;
  final int? manualProgressPct;
  final String? notes;

  // Computed by the server on every read - never sent back on create/update.
  final double? currentValue;
  final double progressPct;
  final bool achieved;
  final int daysRemaining;

  GoalModel({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.targetValue,
    this.manualProgressPct,
    this.notes,
    this.currentValue,
    this.progressPct = 0,
    this.achieved = false,
    this.daysRemaining = 0,
  });

  static final DateFormat _formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'],
      title: json['title'] ?? '',
      category: GoalCategoryEnum.fromValue(json['category']),
      status: GoalStatusEnum.fromValue(json['status']),
      targetValue: json['targetValue'] != null
          ? (json['targetValue'] as num).toDouble()
          : null,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      manualProgressPct: json['manualProgressPct'],
      notes: json['notes'],
      currentValue: json['currentValue'] != null
          ? (json['currentValue'] as num).toDouble()
          : null,
      progressPct: json['progressPct'] != null
          ? (json['progressPct'] as num).toDouble()
          : 0,
      achieved: json['achieved'] ?? false,
      daysRemaining: json['daysRemaining'] ?? 0,
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'title': title,
    'category': category.value,
    'targetValue': targetValue,
    'startDate': _formatter.format(startDate),
    'endDate': _formatter.format(endDate),
    'manualProgressPct': manualProgressPct,
    'notes': notes,
  };

  Map<String, dynamic> toUpdateJson() => {
    'title': title,
    'category': category.value,
    'status': status.value,
    'targetValue': targetValue,
    'startDate': _formatter.format(startDate),
    'endDate': _formatter.format(endDate),
    'manualProgressPct': manualProgressPct,
    'notes': notes,
  };

  GoalModel copyWith({
    String? title,
    GoalCategoryEnum? category,
    GoalStatusEnum? status,
    double? targetValue,
    DateTime? startDate,
    DateTime? endDate,
    int? manualProgressPct,
    String? notes,
  }) {
    return GoalModel(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      status: status ?? this.status,
      targetValue: targetValue ?? this.targetValue,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      manualProgressPct: manualProgressPct ?? this.manualProgressPct,
      notes: notes ?? this.notes,
      currentValue: currentValue,
      progressPct: progressPct,
      achieved: achieved,
      daysRemaining: daysRemaining,
    );
  }
}
