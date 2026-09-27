import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../enums/plan_item_status_enum.dart';
import '../models/planner_models.dart';

/// All calls to tm-server's `/api/v1/planner` endpoints (see
/// PlannerController there for the full list).
class PlannerService {
  static const _json = {'Content-Type': 'application/json'};
  static String get _base => ApiConstants.plannerURL;

  static dynamic _decode(http.Response response, String action) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Failed to $action';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          message = '$message: ${body['message']}';
        }
      } catch (_) {}
      throw Exception(message);
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  // ---------------------------------------------------------------- settings

  static Future<PlannerSettingsModel> getSettings() async {
    final r = await http.get(Uri.parse('$_base/settings'));
    return PlannerSettingsModel.fromJson(_decode(r, 'load planner settings'));
  }

  static Future<PlannerSettingsModel> updateSettings(List<double> dayHours) async {
    final r = await http.put(
      Uri.parse('$_base/settings'),
      headers: _json,
      body: jsonEncode(PlannerSettingsModel.toJson(dayHours)),
    );
    return PlannerSettingsModel.fromJson(_decode(r, 'save planner settings'));
  }

  // ------------------------------------------------------------- focus areas

  static Future<List<FocusAreaModel>> getFocusAreas() async {
    final r = await http.get(Uri.parse('$_base/focusAreas'));
    final List data = _decode(r, 'load focus areas');
    return data.map((e) => FocusAreaModel.fromJson(e)).toList();
  }

  static Future<FocusAreaModel> createFocusArea(Map<String, dynamic> data) async {
    final r = await http.post(Uri.parse('$_base/focusAreas'),
        headers: _json, body: jsonEncode(data));
    return FocusAreaModel.fromJson(_decode(r, 'create focus area'));
  }

  static Future<FocusAreaModel> updateFocusArea(int id, Map<String, dynamic> data) async {
    final r = await http.put(Uri.parse('$_base/focusAreas/$id'),
        headers: _json, body: jsonEncode(data));
    return FocusAreaModel.fromJson(_decode(r, 'update focus area'));
  }

  static Future<void> deleteFocusArea(int id) async {
    final r = await http.delete(Uri.parse('$_base/focusAreas/$id'));
    _decode(r, 'delete focus area');
  }

  // -------------------------------------------------------------------- week

  static Future<WeekPlanModel> getWeek(DateTime weekStart) async {
    final r = await http.get(Uri.parse(
        '$_base/week?weekStart=${plannerDateFormat.format(weekStart)}'));
    return WeekPlanModel.fromJson(_decode(r, 'load week plan'));
  }

  static Future<WeekPlanModel> carryOver(DateTime weekStart) async {
    final r = await http.post(Uri.parse(
        '$_base/week/carryOver?weekStart=${plannerDateFormat.format(weekStart)}'));
    return WeekPlanModel.fromJson(_decode(r, 'carry over tasks'));
  }

  // ---------------------------------------------------------------- overview

  static Future<PlannerOverviewModel> getOverview({int weeks = 8}) async {
    final r = await http.get(Uri.parse('$_base/overview?weeks=$weeks'));
    return PlannerOverviewModel.fromJson(_decode(r, 'load planner overview'));
  }

  // ------------------------------------------------------------------- month

  static Future<MonthPlanModel> getMonth(int year, int month) async {
    final r = await http.get(Uri.parse('$_base/month?year=$year&month=$month'));
    return MonthPlanModel.fromJson(_decode(r, 'load month plan'));
  }

  // ------------------------------------------------------------ weekly tasks

  static Future<void> createTask(Map<String, dynamic> data) async {
    final r = await http.post(Uri.parse('$_base/tasks'),
        headers: _json, body: jsonEncode(data));
    _decode(r, 'create task');
  }

  static Future<void> updateTask(int id, Map<String, dynamic> data) async {
    final r = await http.put(Uri.parse('$_base/tasks/$id'),
        headers: _json, body: jsonEncode(data));
    _decode(r, 'update task');
  }

  static Future<void> deleteTask(int id) async {
    final r = await http.delete(Uri.parse('$_base/tasks/$id'));
    _decode(r, 'delete task');
  }

  static Future<void> evaluateTask(int id, PlannerEvaluation evaluation) async {
    final r = await http.put(Uri.parse('$_base/tasks/$id/evaluation'),
        headers: _json, body: jsonEncode(evaluation.toJson()));
    _decode(r, 'evaluate task');
  }

  // ------------------------------------------------------ monthly objectives

  static Future<void> createObjective(Map<String, dynamic> data) async {
    final r = await http.post(Uri.parse('$_base/objectives'),
        headers: _json, body: jsonEncode(data));
    _decode(r, 'create objective');
  }

  static Future<void> updateObjective(int id, Map<String, dynamic> data) async {
    final r = await http.put(Uri.parse('$_base/objectives/$id'),
        headers: _json, body: jsonEncode(data));
    _decode(r, 'update objective');
  }

  static Future<void> deleteObjective(int id) async {
    final r = await http.delete(Uri.parse('$_base/objectives/$id'));
    _decode(r, 'delete objective');
  }

  static Future<void> evaluateObjective(int id, PlannerEvaluation evaluation) async {
    final r = await http.put(Uri.parse('$_base/objectives/$id/evaluation'),
        headers: _json, body: jsonEncode(evaluation.toJson()));
    _decode(r, 'evaluate objective');
  }
}

/// Body of PUT .../evaluation -- replaces the whole evaluation.
class PlannerEvaluation {
  final PlanItemStatusEnum status;
  final int? score;
  final double? actualHours;
  final String? evaluationNotes;

  const PlannerEvaluation({
    required this.status,
    this.score,
    this.actualHours,
    this.evaluationNotes,
  });

  Map<String, dynamic> toJson() => {
        'status': status.value,
        'score': score,
        'actualHours': actualHours,
        'evaluationNotes': evaluationNotes,
      };
}
