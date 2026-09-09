import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tm_dashboard/models/trade_model.dart';

import '../constants/api_constants.dart';

class TradeService {
  static Future<void> create(List<dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.tradeURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create trades');
    }
  }

  static Future<List<Trade>> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.tradeURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch trades');
    }

    final List data = jsonDecode(response.body);
    return Future.wait(data.map((e) => Trade.fromJson(e)).toList());
  }

  /// PATCH /trade/{id}/review -- confirms the review-flow fields for a
  /// trade and sets reviewedAt server-side. Null-means-unchanged: only keys
  /// present in [payload] are applied, so callers should build it
  /// explicitly (including an empty list for mistakeTags when the user
  /// picked none, so it actually gets cleared rather than left untouched).
  static Future<Trade> review(int id, Map<String, dynamic> payload) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.tradeURL}/$id/review'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response, 'Failed to save review'));
    }

    return Trade.fromJson(jsonDecode(response.body));
  }

  /// POST /trade/{id}/suggest -- explicit, cost-gated AI-suggestion call
  /// (Phase 5). Never automatic. Surfaces the server's own error message
  /// (already reviewed / AI disabled / LLM failure) rather than a generic
  /// one, so the review screen can show the user why it failed.
  static Future<Trade> suggest(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.tradeURL}/$id/suggest'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(response, 'Failed to get AI suggestions'),
      );
    }

    return Trade.fromJson(jsonDecode(response.body));
  }

  static String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
    } catch (_) {
      // Response body wasn't the expected ErrorResponse JSON shape --
      // fall back below rather than throwing from inside error handling.
    }
    return fallback;
  }
}
