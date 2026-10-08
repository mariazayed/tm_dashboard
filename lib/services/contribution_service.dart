import 'dart:convert';

import '../constants/api_constants.dart';
import '../models/invest/contribution_model.dart';
import '../models/invest/contribution_status_model.dart';
import '../models/invest/invest_settings_model.dart';
import '../models/invest/performance_model.dart';
import 'api_client.dart';

/// A failed call to the invest API.
class InvestApiException implements Exception {
  const InvestApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ContributionService {
  ContributionService({ApiClient? api}) : _api = api ?? ApiClient.shared;

  static final ContributionService shared = ContributionService();

  final ApiClient _api;

  static const _json = {'Content-Type': 'application/json'};

  String get _base => '${ApiConstants.investURL}/contributions';

  Future<InvestSettingsModel> getSettings() async {
    final response = await _api.get(
      Uri.parse('${ApiConstants.investURL}/settings'),
    );
    _check(response.statusCode, response.body, expected: {200});
    return InvestSettingsModel.fromJson(jsonDecode(response.body));
  }

  /// [range] only trims the chart series: 3M, 6M, 1Y or ALL.
  Future<PerformanceModel> getPerformance({String range = 'ALL'}) async {
    final response = await _api.get(
      Uri.parse('${ApiConstants.investURL}/performance?range=$range'),
    );
    _check(response.statusCode, response.body, expected: {200});
    return PerformanceModel.fromJson(jsonDecode(response.body));
  }

  Future<PriceRefreshResult> refreshPrices() async {
    final response = await _api.post(
      Uri.parse('${ApiConstants.investURL}/prices/refresh'),
    );
    _check(response.statusCode, response.body, expected: {200});
    return PriceRefreshResult.fromJson(jsonDecode(response.body));
  }

  Future<List<ContributionModel>> getAll() async {
    final response = await _api.get(Uri.parse(_base));
    _check(response.statusCode, response.body, expected: {200});
    return (jsonDecode(response.body) as List)
        .map((e) => ContributionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ContributionStatusModel> getStatus() async {
    final response = await _api.get(Uri.parse('$_base/status'));
    _check(response.statusCode, response.body, expected: {200});
    return ContributionStatusModel.fromJson(jsonDecode(response.body));
  }

  Future<ContributionModel> create(Map<String, dynamic> data) async {
    final response = await _api.post(
      Uri.parse(_base),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, expected: {200, 201});
    return ContributionModel.fromJson(jsonDecode(response.body));
  }

  Future<ContributionModel> update(int id, Map<String, dynamic> data) async {
    final response = await _api.put(
      Uri.parse('$_base/$id'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, expected: {200});
    return ContributionModel.fromJson(jsonDecode(response.body));
  }

  Future<void> delete(int id) async {
    final response = await _api.delete(Uri.parse('$_base/$id'));
    _check(response.statusCode, response.body, expected: {200, 204});
  }

  Future<String> exportCsv() async {
    final response = await _api.get(Uri.parse('$_base/export'));
    _check(response.statusCode, response.body, expected: {200});
    return response.body;
  }

  /// All-or-nothing on the server: a 422 carries the per-row problems.
  Future<CsvImportResult> importCsv(String csv) async {
    final response = await _api.post(
      Uri.parse('$_base/import'),
      headers: {'Content-Type': 'text/csv'},
      body: csv,
    );
    if (response.statusCode == 200 || response.statusCode == 422) {
      return CsvImportResult.fromJson(jsonDecode(response.body));
    }
    _check(response.statusCode, response.body, expected: {200});
    throw const InvestApiException('Import failed');
  }

  void _check(int status, String body, {required Set<int> expected}) {
    if (expected.contains(status)) return;
    throw InvestApiException(messageFrom(status, body), statusCode: status);
  }

  static String messageFrom(int status, String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        final errors = json['validationErrors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.map((e) => '${e['field']}: ${e['message']}').join('\n');
        }
        if (json['message'] is String) return json['message'] as String;
      }
    } catch (_) {}
    return 'Request failed ($status)';
  }
}
