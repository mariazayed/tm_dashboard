import 'dart:convert';

import '../constants/api_constants.dart';
import '../models/invest/holding_model.dart';
import 'api_client.dart';
import 'contribution_service.dart';

/// The funds you buy.
class HoldingService {
  HoldingService({ApiClient? api}) : _api = api ?? ApiClient.shared;

  static final HoldingService shared = HoldingService();

  final ApiClient _api;

  static const _json = {'Content-Type': 'application/json'};

  String get _base => '${ApiConstants.investURL}/holdings';

  /// In the order they were added; the first is the primary fund.
  Future<List<HoldingModel>> list() async {
    final response = await _api.get(Uri.parse(_base));
    _check(response.statusCode, response.body, {200});
    return (jsonDecode(response.body) as List)
        .map((e) => HoldingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HoldingModel> create(Map<String, dynamic> data) async {
    final response = await _api.post(
      Uri.parse(_base),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, {201});
    return HoldingModel.fromJson(jsonDecode(response.body));
  }

  Future<HoldingModel> update(int id, Map<String, dynamic> data) async {
    final response = await _api.put(
      Uri.parse('$_base/$id'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, {200});
    return HoldingModel.fromJson(jsonDecode(response.body));
  }

  Future<void> delete(int id) async {
    final response = await _api.delete(Uri.parse('$_base/$id'));
    _check(response.statusCode, response.body, {204});
  }

  void _check(int status, String body, Set<int> expected) {
    if (expected.contains(status)) return;
    throw InvestApiException(
      ContributionService.messageFrom(status, body),
      statusCode: status,
    );
  }
}
