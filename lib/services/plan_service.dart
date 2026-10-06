import 'dart:convert';

import '../constants/api_constants.dart';
import '../models/invest/invest_settings_model.dart';
import '../models/invest/plan_model.dart';
import 'api_client.dart';
import 'contribution_service.dart';

/// Rules, plan settings and reminders.
class PlanService {
  PlanService({ApiClient? api}) : _api = api ?? ApiClient.shared;

  static final PlanService shared = PlanService();

  final ApiClient _api;

  static const _json = {'Content-Type': 'application/json'};

  String get _base => ApiConstants.investURL;

  Future<List<RuleModel>> rules() async {
    final response = await _api.get(Uri.parse('$_base/rules'));
    _check(response.statusCode, response.body, {200});
    return _rules(response.body);
  }

  Future<RuleModel> createRule(String text) async {
    final response = await _api.post(
      Uri.parse('$_base/rules'),
      headers: _json,
      body: jsonEncode({'text': text}),
    );
    _check(response.statusCode, response.body, {200, 201});
    return RuleModel.fromJson(jsonDecode(response.body));
  }

  Future<RuleModel> updateRule(int id, String text) async {
    final response = await _api.put(
      Uri.parse('$_base/rules/$id'),
      headers: _json,
      body: jsonEncode({'text': text}),
    );
    _check(response.statusCode, response.body, {200});
    return RuleModel.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteRule(int id) async {
    final response = await _api.delete(Uri.parse('$_base/rules/$id'));
    _check(response.statusCode, response.body, {200, 204});
  }

  /// [ids] must be every current rule exactly once, in the new order.
  Future<List<RuleModel>> reorderRules(List<int> ids) async {
    final response = await _api.put(
      Uri.parse('$_base/rules/order'),
      headers: _json,
      body: jsonEncode({'ids': ids}),
    );
    _check(response.statusCode, response.body, {200});
    return _rules(response.body);
  }

  Future<InvestSettingsModel> updateSettings(Map<String, dynamic> data) async {
    final response = await _api.put(
      Uri.parse('$_base/settings'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, {200});
    return InvestSettingsModel.fromJson(jsonDecode(response.body));
  }

  Future<ReminderStatusModel> reminderStatus() async {
    final response = await _api.get(Uri.parse('$_base/reminders'));
    _check(response.statusCode, response.body, {200});
    return ReminderStatusModel.fromJson(jsonDecode(response.body));
  }

  Future<ReminderTestResult> sendTestReminder() async {
    final response = await _api.post(Uri.parse('$_base/reminders/test'));
    _check(response.statusCode, response.body, {200});
    return ReminderTestResult.fromJson(jsonDecode(response.body));
  }

  /// Everything the tracker stores, as the server's JSON export (pretty-printed
  /// would be wasted bytes here, so it is returned as the server sent it).
  Future<String> exportJson() async {
    final response = await _api.get(Uri.parse('$_base/export'));
    _check(response.statusCode, response.body, {200});
    return response.body;
  }

  List<RuleModel> _rules(String body) => (jsonDecode(body) as List)
      .map((e) => RuleModel.fromJson(e as Map<String, dynamic>))
      .toList();

  void _check(int status, String body, Set<int> expected) {
    if (expected.contains(status)) return;
    throw InvestApiException(
      ContributionService.messageFrom(status, body),
      statusCode: status,
    );
  }
}
