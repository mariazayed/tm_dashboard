import 'dart:convert';

import '../constants/api_constants.dart';
import '../models/invest/contribution_model.dart';
import '../models/invest/journal_model.dart';
import 'api_client.dart';
import 'contribution_service.dart';

class JournalService {
  JournalService({ApiClient? api}) : _api = api ?? ApiClient.shared;

  static final JournalService shared = JournalService();

  final ApiClient _api;

  static const _json = {'Content-Type': 'application/json'};
  static const pageSize = 30;

  String get _base => '${ApiConstants.investURL}/journal';

  Future<JournalPage> list({
    String? tag,
    JournalEntryType? type,
    String? query,
    DateTime? from,
    DateTime? to,
    int page = 0,
    int size = pageSize,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'size': '$size',
      if (tag != null && tag.isNotEmpty) 'tag': tag,
      if (type != null) 'type': type.api,
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (from != null) 'from': ContributionModel.dateString(from),
      if (to != null) 'to': ContributionModel.dateString(to),
    };
    final response = await _api.get(
      Uri.parse(_base).replace(queryParameters: params),
    );
    _check(response.statusCode, response.body, {200});
    return JournalPage.fromJson(jsonDecode(response.body));
  }

  Future<List<JournalTagModel>> tags() async {
    final response = await _api.get(Uri.parse('$_base/tags'));
    _check(response.statusCode, response.body, {200});
    return (jsonDecode(response.body) as List)
        .map((e) => JournalTagModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CheckinTemplateModel> checkinTemplate() async {
    final response = await _api.get(Uri.parse('$_base/checkin-template'));
    _check(response.statusCode, response.body, {200});
    return CheckinTemplateModel.fromJson(jsonDecode(response.body));
  }

  Future<JournalEntryModel> create(Map<String, dynamic> data) async {
    final response = await _api.post(
      Uri.parse(_base),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, {200, 201});
    return JournalEntryModel.fromJson(jsonDecode(response.body));
  }

  Future<JournalEntryModel> update(int id, Map<String, dynamic> data) async {
    final response = await _api.put(
      Uri.parse('$_base/$id'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, {200});
    return JournalEntryModel.fromJson(jsonDecode(response.body));
  }

  Future<void> delete(int id) async {
    final response = await _api.delete(Uri.parse('$_base/$id'));
    _check(response.statusCode, response.body, {200, 204});
  }

  void _check(int status, String body, Set<int> expected) {
    if (expected.contains(status)) return;
    throw InvestApiException(
      ContributionService.messageFrom(status, body),
      statusCode: status,
    );
  }
}
