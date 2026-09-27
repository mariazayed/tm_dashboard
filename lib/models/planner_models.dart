import 'package:intl/intl.dart';

import '../enums/plan_item_status_enum.dart';

/// Client-side models for the Planner feature (tm-server's
/// `trademind.tm_server.planner` package). Capacity, allocations,
/// evaluation stats and objective roll-ups are all computed server-side
/// and simply read here.

final DateFormat plannerDateFormat = DateFormat('yyyy-MM-dd');

double _d(dynamic v) => v == null ? 0 : (v as num).toDouble();
double? _dn(dynamic v) => v == null ? null : (v as num).toDouble();

/// Monday of the week containing [date] (time stripped).
DateTime mondayOf(DateTime date) {
  final d = DateTime(date.year, date.month, date.day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

class FocusAreaModel {
  final int id;
  final String name;
  final String color;
  final String? icon;
  final double maxPercent;
  final int sortOrder;
  final bool archived;
  final String? notes;

  const FocusAreaModel({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    required this.maxPercent,
    this.sortOrder = 0,
    this.archived = false,
    this.notes,
  });

  factory FocusAreaModel.fromJson(Map<String, dynamic> json) => FocusAreaModel(
        id: json['id'],
        name: json['name'] ?? '',
        color: json['color'] ?? '#6366F1',
        icon: json['icon'],
        maxPercent: _d(json['maxPercent']),
        sortOrder: json['sortOrder'] ?? 0,
        archived: json['archived'] ?? false,
        notes: json['notes'],
      );
}

class PlannerSettingsModel {
  /// Hours per weekday, index 0 = Monday ... 6 = Sunday.
  final List<double> dayHours;
  final double weeklyHours;
  final int workingDays;

  const PlannerSettingsModel({
    required this.dayHours,
    required this.weeklyHours,
    required this.workingDays,
  });

  static const _keys = [
    'mondayHours',
    'tuesdayHours',
    'wednesdayHours',
    'thursdayHours',
    'fridayHours',
    'saturdayHours',
    'sundayHours',
  ];

  factory PlannerSettingsModel.fromJson(Map<String, dynamic> json) =>
      PlannerSettingsModel(
        dayHours: _keys.map((k) => _d(json[k])).toList(),
        weeklyHours: _d(json['weeklyHours']),
        workingDays: json['workingDays'] ?? 0,
      );

  static Map<String, dynamic> toJson(List<double> dayHours) => {
        for (var i = 0; i < 7; i++) _keys[i]: dayHours[i],
      };
}

class WeeklyTaskModel {
  final int id;
  final DateTime weekStart;
  final String title;
  final String? notes;
  final FocusAreaModel focusArea;
  final int? monthlyObjectiveId;
  final String? monthlyObjectiveTitle;
  final double estimatedHours;
  final PlanItemStatusEnum status;
  final int? score;
  final double? actualHours;
  final String? evaluationNotes;
  /// Extra working hours: planned work like any task, whose hours are also
  /// added to the week's capacity and its Focus Area's budget.
  final bool isExtra;

  const WeeklyTaskModel({
    required this.id,
    required this.weekStart,
    required this.title,
    this.notes,
    required this.focusArea,
    this.monthlyObjectiveId,
    this.monthlyObjectiveTitle,
    required this.estimatedHours,
    required this.status,
    this.score,
    this.actualHours,
    this.evaluationNotes,
    this.isExtra = false,
  });

  factory WeeklyTaskModel.fromJson(Map<String, dynamic> json) => WeeklyTaskModel(
        id: json['id'],
        weekStart: DateTime.parse(json['weekStart']),
        title: json['title'] ?? '',
        notes: json['notes'],
        focusArea: FocusAreaModel.fromJson(json['focusArea']),
        monthlyObjectiveId: json['monthlyObjectiveId'],
        monthlyObjectiveTitle: json['monthlyObjectiveTitle'],
        estimatedHours: _d(json['estimatedHours']),
        status: PlanItemStatusEnum.fromValue(json['status']),
        score: json['score'],
        actualHours: _dn(json['actualHours']),
        evaluationNotes: json['evaluationNotes'],
        isExtra: json['extra'] ?? false,
      );
}

class MonthlyObjectiveModel {
  final int id;
  final int planYear;
  final int planMonth;
  final String title;
  final String? notes;
  final FocusAreaModel focusArea;
  final double estimatedHours;
  final PlanItemStatusEnum status;
  final int? score;
  final double? actualHours;
  final String? evaluationNotes;

  final int linkedTaskCount;
  final int linkedDoneCount;
  final double linkedPlannedHours;
  final double linkedCreditedHours;
  final double progressPct;

  const MonthlyObjectiveModel({
    required this.id,
    required this.planYear,
    required this.planMonth,
    required this.title,
    this.notes,
    required this.focusArea,
    required this.estimatedHours,
    required this.status,
    this.score,
    this.actualHours,
    this.evaluationNotes,
    this.linkedTaskCount = 0,
    this.linkedDoneCount = 0,
    this.linkedPlannedHours = 0,
    this.linkedCreditedHours = 0,
    this.progressPct = 0,
  });

  factory MonthlyObjectiveModel.fromJson(Map<String, dynamic> json) =>
      MonthlyObjectiveModel(
        id: json['id'],
        planYear: json['planYear'],
        planMonth: json['planMonth'],
        title: json['title'] ?? '',
        notes: json['notes'],
        focusArea: FocusAreaModel.fromJson(json['focusArea']),
        estimatedHours: _d(json['estimatedHours']),
        status: PlanItemStatusEnum.fromValue(json['status']),
        score: json['score'],
        actualHours: _dn(json['actualHours']),
        evaluationNotes: json['evaluationNotes'],
        linkedTaskCount: json['linkedTaskCount'] ?? 0,
        linkedDoneCount: json['linkedDoneCount'] ?? 0,
        linkedPlannedHours: _d(json['linkedPlannedHours']),
        linkedCreditedHours: _d(json['linkedCreditedHours']),
        progressPct: _d(json['progressPct']),
      );

  String get monthLabel => DateFormat('MMM yyyy').format(DateTime(planYear, planMonth));
}

class AreaAllocationModel {
  final FocusAreaModel focusArea;
  final int itemCount;
  final double plannedHours;
  final double actualHours;
  final double plannedPct;
  final double actualPct;
  final double maxPercent;
  /// Extra hours dedicated to this area this period (already included in
  /// [allowedHours]).
  final double extraHours;
  final double allowedHours;
  final bool overLimit;

  /// Share of this area's own budget that's planned (100% = at its max).
  double get budgetUsedPct => allowedHours > 0 ? plannedHours / allowedHours * 100 : (plannedHours > 0 ? 100 : 0);

  const AreaAllocationModel({
    required this.focusArea,
    required this.itemCount,
    required this.plannedHours,
    required this.actualHours,
    required this.plannedPct,
    required this.actualPct,
    required this.maxPercent,
    this.extraHours = 0,
    required this.allowedHours,
    required this.overLimit,
  });

  factory AreaAllocationModel.fromJson(Map<String, dynamic> json) =>
      AreaAllocationModel(
        focusArea: FocusAreaModel.fromJson(json['focusArea']),
        itemCount: json['itemCount'] ?? 0,
        plannedHours: _d(json['plannedHours']),
        actualHours: _d(json['actualHours']),
        plannedPct: _d(json['plannedPct']),
        actualPct: _d(json['actualPct']),
        maxPercent: _d(json['maxPercent']),
        extraHours: _d(json['extraHours']),
        allowedHours: _d(json['allowedHours']),
        overLimit: json['overLimit'] ?? false,
      );
}

class EvaluationSummaryModel {
  final int totalCount;
  final int doneCount;
  final int partialCount;
  final int missedCount;
  final int pendingCount;
  final double? averageScore;
  final double completionPct;
  final double plannedHours;
  final double actualHours;

  const EvaluationSummaryModel({
    required this.totalCount,
    required this.doneCount,
    required this.partialCount,
    required this.missedCount,
    required this.pendingCount,
    this.averageScore,
    required this.completionPct,
    required this.plannedHours,
    required this.actualHours,
  });

  factory EvaluationSummaryModel.fromJson(Map<String, dynamic>? json) {
    json ??= const {};
    return EvaluationSummaryModel(
      totalCount: json['totalCount'] ?? 0,
      doneCount: json['doneCount'] ?? 0,
      partialCount: json['partialCount'] ?? 0,
      missedCount: json['missedCount'] ?? 0,
      pendingCount: json['pendingCount'] ?? 0,
      averageScore: _dn(json['averageScore']),
      completionPct: _d(json['completionPct']),
      plannedHours: _d(json['plannedHours']),
      actualHours: _d(json['actualHours']),
    );
  }
}

/// Capacity fields shared by the week and month views.
abstract class PlanPeriodModel {
  int get workingDays;
  double get baseHours;
  double get extraHours;
  double get capacityHours;
  double get plannedHours;
  double get remainingHours;
  bool get overCapacity;
  List<AreaAllocationModel> get areas;
  EvaluationSummaryModel get evaluation;
}

class WeekPlanModel implements PlanPeriodModel {
  final DateTime weekStart;
  final DateTime weekEnd;
  @override
  final int workingDays;
  @override
  final double baseHours;
  @override
  final double extraHours;
  final String? notes;
  @override
  final double capacityHours;
  @override
  final double plannedHours;
  @override
  final double remainingHours;
  @override
  final bool overCapacity;
  final List<WeeklyTaskModel> tasks;
  @override
  final List<AreaAllocationModel> areas;
  @override
  final EvaluationSummaryModel evaluation;
  final List<MonthlyObjectiveModel> objectives;

  const WeekPlanModel({
    required this.weekStart,
    required this.weekEnd,
    required this.workingDays,
    required this.baseHours,
    required this.extraHours,
    this.notes,
    required this.capacityHours,
    required this.plannedHours,
    required this.remainingHours,
    required this.overCapacity,
    required this.tasks,
    required this.areas,
    required this.evaluation,
    required this.objectives,
  });

  factory WeekPlanModel.fromJson(Map<String, dynamic> json) => WeekPlanModel(
        weekStart: DateTime.parse(json['weekStart']),
        weekEnd: DateTime.parse(json['weekEnd']),
        workingDays: json['workingDays'] ?? 0,
        baseHours: _d(json['baseHours']),
        extraHours: _d(json['extraHours']),
        notes: json['notes'],
        capacityHours: _d(json['capacityHours']),
        plannedHours: _d(json['plannedHours']),
        remainingHours: _d(json['remainingHours']),
        overCapacity: json['overCapacity'] ?? false,
        tasks: ((json['tasks'] ?? []) as List)
            .map((e) => WeeklyTaskModel.fromJson(e))
            .toList(),
        areas: ((json['areas'] ?? []) as List)
            .map((e) => AreaAllocationModel.fromJson(e))
            .toList(),
        evaluation: EvaluationSummaryModel.fromJson(json['evaluation']),
        objectives: ((json['objectives'] ?? []) as List)
            .map((e) => MonthlyObjectiveModel.fromJson(e))
            .toList(),
      );
}

class WeekSnapshotModel {
  final DateTime weekStart;
  final double capacityHours;
  final double plannedHours;
  final double actualHours;
  final int taskCount;
  final int doneCount;
  final double completionPct;
  final double extraHours;
  final int evaluatedCount;
  final double? averageScore;

  const WeekSnapshotModel({
    required this.weekStart,
    required this.capacityHours,
    required this.plannedHours,
    required this.actualHours,
    required this.taskCount,
    required this.doneCount,
    required this.completionPct,
    this.extraHours = 0,
    this.evaluatedCount = 0,
    this.averageScore,
  });

  factory WeekSnapshotModel.fromJson(Map<String, dynamic> json) =>
      WeekSnapshotModel(
        weekStart: DateTime.parse(json['weekStart']),
        capacityHours: _d(json['capacityHours']),
        plannedHours: _d(json['plannedHours']),
        actualHours: _d(json['actualHours']),
        taskCount: json['taskCount'] ?? 0,
        doneCount: json['doneCount'] ?? 0,
        completionPct: _d(json['completionPct']),
        extraHours: _d(json['extraHours']),
        evaluatedCount: json['evaluatedCount'] ?? 0,
        averageScore: _dn(json['averageScore']),
      );
}

class MonthPlanModel implements PlanPeriodModel {
  final int year;
  final int month;
  @override
  final int workingDays;
  @override
  final double baseHours;
  @override
  final double extraHours;
  @override
  final double capacityHours;
  @override
  final double plannedHours;
  @override
  final double remainingHours;
  @override
  final bool overCapacity;
  final List<MonthlyObjectiveModel> objectives;
  @override
  final List<AreaAllocationModel> areas;
  @override
  final EvaluationSummaryModel evaluation;
  final List<WeekSnapshotModel> weeks;

  const MonthPlanModel({
    required this.year,
    required this.month,
    required this.workingDays,
    required this.baseHours,
    required this.extraHours,
    required this.capacityHours,
    required this.plannedHours,
    required this.remainingHours,
    required this.overCapacity,
    required this.objectives,
    required this.areas,
    required this.evaluation,
    required this.weeks,
  });

  factory MonthPlanModel.fromJson(Map<String, dynamic> json) => MonthPlanModel(
        year: json['year'],
        month: json['month'],
        workingDays: json['workingDays'] ?? 0,
        baseHours: _d(json['baseHours']),
        extraHours: _d(json['extraHours']),
        capacityHours: _d(json['capacityHours']),
        plannedHours: _d(json['plannedHours']),
        remainingHours: _d(json['remainingHours']),
        overCapacity: json['overCapacity'] ?? false,
        objectives: ((json['objectives'] ?? []) as List)
            .map((e) => MonthlyObjectiveModel.fromJson(e))
            .toList(),
        areas: ((json['areas'] ?? []) as List)
            .map((e) => AreaAllocationModel.fromJson(e))
            .toList(),
        evaluation: EvaluationSummaryModel.fromJson(json['evaluation']),
        weeks: ((json['weeks'] ?? []) as List)
            .map((e) => WeekSnapshotModel.fromJson(e))
            .toList(),
      );
}

/// GET /planner/overview -- the Home dashboard's Planner section.
class PlannerOverviewModel {
  final WeekPlanModel currentWeek;
  final MonthPlanModel currentMonth;
  /// Oldest first, ending with the current week.
  final List<WeekSnapshotModel> history;
  final int planningStreak;
  final int evaluationStreak;
  final int daysLeftInWeek;
  final List<AreaAllocationModel> areaMix;

  const PlannerOverviewModel({
    required this.currentWeek,
    required this.currentMonth,
    required this.history,
    required this.planningStreak,
    required this.evaluationStreak,
    required this.daysLeftInWeek,
    required this.areaMix,
  });

  factory PlannerOverviewModel.fromJson(Map<String, dynamic> json) =>
      PlannerOverviewModel(
        currentWeek: WeekPlanModel.fromJson(json['currentWeek']),
        currentMonth: MonthPlanModel.fromJson(json['currentMonth']),
        history: ((json['history'] ?? []) as List)
            .map((e) => WeekSnapshotModel.fromJson(e))
            .toList(),
        planningStreak: json['planningStreak'] ?? 0,
        evaluationStreak: json['evaluationStreak'] ?? 0,
        daysLeftInWeek: json['daysLeftInWeek'] ?? 0,
        areaMix: ((json['areaMix'] ?? []) as List)
            .map((e) => AreaAllocationModel.fromJson(e))
            .toList(),
      );
}
