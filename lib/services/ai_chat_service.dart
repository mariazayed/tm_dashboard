import 'dart:convert';

import '../constants/api_constants.dart';
import '../models/invest/ai_chat_model.dart';
import '../models/invest/insights_model.dart';
import 'api_client.dart';
import 'contribution_service.dart';

/// "Ask your journal": questions about your own rules, journal and notes.
/// Nothing here changes your data; the server answers from what you wrote.
class AiChatService {
  AiChatService({ApiClient? api}) : _api = api ?? ApiClient.shared;

  static final AiChatService shared = AiChatService();

  final ApiClient _api;

  String get _base => '${ApiConstants.investURL}/ai';

  /// [history] is the earlier conversation, already fitted with
  /// [ChatHistory.build]; the server keeps none of its own.
  Future<ChatAnswer> chat({
    required String question,
    List<ChatTurn> history = const [],
    bool includeJournal = true,
    bool includeNotes = true,
  }) async {
    final response = await _api.post(
      Uri.parse('$_base/chat'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question': question,
        'history': history.map((t) => t.toJson()).toList(),
        'includeJournal': includeJournal,
        'includeNotes': includeNotes,
      }),
    );
    _check(response.statusCode, response.body);
    return ChatAnswer.fromJson(jsonDecode(response.body));
  }

  Future<AiUsageModel> usage() async {
    final response = await _api.get(Uri.parse('$_base/usage'));
    _check(response.statusCode, response.body);
    return AiUsageModel.fromJson(jsonDecode(response.body));
  }

  /// Calls per day for the last [days] days (1 to 90), against the daily cap.
  Future<AiUsageHistoryModel> usageHistory({int days = 30}) async {
    final response = await _api.get(Uri.parse('$_base/usage/history?days=$days'));
    _check(response.statusCode, response.body);
    return AiUsageHistoryModel.fromJson(jsonDecode(response.body));
  }

  void _check(int status, String body) {
    if (status == 200) return;
    throw InvestApiException(
      ContributionService.messageFrom(status, body),
      statusCode: status,
    );
  }
}
