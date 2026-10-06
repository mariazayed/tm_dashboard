import 'dart:convert';

import '../constants/api_constants.dart';
import '../models/invest/journal_model.dart';
import '../models/invest/learning_model.dart';
import 'api_client.dart';
import 'contribution_service.dart';

class LearningService {
  LearningService({ApiClient? api}) : _api = api ?? ApiClient.shared;

  static final LearningService shared = LearningService();

  final ApiClient _api;

  static const _json = {'Content-Type': 'application/json'};
  static const pageSize = 30;

  String get _base => '${ApiConstants.investURL}/learning';

  // ---- sources ----------------------------------------------------------------------------

  Future<List<LearningSourceModel>> sources({SourceStatus? status}) async {
    final uri = Uri.parse(
      '$_base/sources',
    ).replace(queryParameters: {if (status != null) 'status': status.api});
    final response = await _api.get(uri);
    _check(response.statusCode, response.body, {200});
    return (jsonDecode(response.body) as List)
        .map((e) => LearningSourceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LearningSourceModel> createSource(Map<String, dynamic> data) async {
    final response = await _api.post(
      Uri.parse('$_base/sources'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, {200, 201});
    return LearningSourceModel.fromJson(jsonDecode(response.body));
  }

  Future<LearningSourceModel> updateSource(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.put(
      Uri.parse('$_base/sources/$id'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, {200});
    return LearningSourceModel.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteSource(int id) async {
    final response = await _api.delete(Uri.parse('$_base/sources/$id'));
    _check(response.statusCode, response.body, {200, 204});
  }

  // ---- notes ------------------------------------------------------------------------------

  Future<LearningNotePage> notes({
    int? sourceId,
    String? tag,
    String? query,
    int page = 0,
    int size = pageSize,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'size': '$size',
      if (sourceId != null) 'sourceId': '$sourceId',
      if (tag != null && tag.isNotEmpty) 'tag': tag,
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
    };
    final response = await _api.get(
      Uri.parse('$_base/notes').replace(queryParameters: params),
    );
    _check(response.statusCode, response.body, {200});
    return LearningNotePage.fromJson(jsonDecode(response.body));
  }

  Future<List<JournalTagModel>> noteTags() async {
    final response = await _api.get(Uri.parse('$_base/notes/tags'));
    _check(response.statusCode, response.body, {200});
    return (jsonDecode(response.body) as List)
        .map((e) => JournalTagModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LearningNoteModel> createNote(Map<String, dynamic> data) async {
    final response = await _api.post(
      Uri.parse('$_base/notes'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, {200, 201});
    return LearningNoteModel.fromJson(jsonDecode(response.body));
  }

  Future<LearningNoteModel> updateNote(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _api.put(
      Uri.parse('$_base/notes/$id'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, {200});
    return LearningNoteModel.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteNote(int id) async {
    final response = await _api.delete(Uri.parse('$_base/notes/$id'));
    _check(response.statusCode, response.body, {200, 204});
  }

  // ---- flashcards -------------------------------------------------------------------------

  Future<List<FlashcardModel>> cards({int? noteId}) async {
    final uri = Uri.parse(
      '$_base/cards',
    ).replace(queryParameters: {if (noteId != null) 'noteId': '$noteId'});
    final response = await _api.get(uri);
    _check(response.statusCode, response.body, {200});
    return _cards(response.body);
  }

  Future<List<FlashcardModel>> dueCards({int limit = 50}) async {
    final response = await _api.get(
      Uri.parse(
        '$_base/cards/due',
      ).replace(queryParameters: {'limit': '$limit'}),
    );
    _check(response.statusCode, response.body, {200});
    return _cards(response.body);
  }

  Future<CardStatsModel> cardStats() async {
    final response = await _api.get(Uri.parse('$_base/cards/stats'));
    _check(response.statusCode, response.body, {200});
    return CardStatsModel.fromJson(jsonDecode(response.body));
  }

  Future<FlashcardModel> createCard(Map<String, dynamic> data) async {
    final response = await _api.post(
      Uri.parse('$_base/cards'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, {200, 201});
    return FlashcardModel.fromJson(jsonDecode(response.body));
  }

  Future<FlashcardModel> updateCard(int id, Map<String, dynamic> data) async {
    final response = await _api.put(
      Uri.parse('$_base/cards/$id'),
      headers: _json,
      body: jsonEncode(data),
    );
    _check(response.statusCode, response.body, {200});
    return FlashcardModel.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteCard(int id) async {
    final response = await _api.delete(Uri.parse('$_base/cards/$id'));
    _check(response.statusCode, response.body, {200, 204});
  }

  Future<FlashcardModel> review(int id, CardGrade grade) async {
    final response = await _api.post(
      Uri.parse('$_base/cards/$id/review'),
      headers: _json,
      body: jsonEncode({'grade': grade.api}),
    );
    _check(response.statusCode, response.body, {200});
    return FlashcardModel.fromJson(jsonDecode(response.body));
  }

  List<FlashcardModel> _cards(String body) => (jsonDecode(body) as List)
      .map((e) => FlashcardModel.fromJson(e as Map<String, dynamic>))
      .toList();

  void _check(int status, String body, Set<int> expected) {
    if (expected.contains(status)) return;
    throw InvestApiException(
      ContributionService.messageFrom(status, body),
      statusCode: status,
    );
  }
}
