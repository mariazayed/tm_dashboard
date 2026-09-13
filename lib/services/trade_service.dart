import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tm_dashboard/models/trade_model.dart';

import '../constants/api_constants.dart';
import '../models/paginated_response.dart';

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

  /// Paginated fetch backing the Trade List/Journal/Review screens -- pages
  /// through POST /trade/search instead of getAll() pulling the entire,
  /// continuously auto-imported trade history into memory on every visit.
  /// Sorted newest-entry-first by default, same ordering feel as getAll()'s
  /// createdAt-desc sort.
  static Future<PaginatedResponse<Trade>> searchPage({
    required int page,
    int size = 30,
    String sortBy = 'entryDateTime',
    String direction = 'DESC',
  }) {
    return fetchSearchPage<Trade>(
      '${ApiConstants.tradeURL}/search',
      (json) => Trade.fromJson(json),
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
    );
  }

  /// Trades for the calendar's "trades overview per day" -- there's no
  /// backend date-range filter (BaseSpecification can't express range
  /// predicates, see the lazy-loading pagination doc), so this pages through
  /// /trade/search newest-first and stops as soon as it walks past the
  /// requested month, rather than pulling the whole auto-imported history
  /// the way a plain getAll() would. Safe to call for any month: pages
  /// newer than [month] are skipped without being kept, and paging stops
  /// the moment a trade older than the month's first day is seen (or the
  /// last page is reached).
  static Future<List<Trade>> getForMonth(DateTime month) async {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 1);

    final List<Trade> result = [];
    int page = 0;
    const size = 50;

    while (true) {
      final response = await searchPage(
        page: page,
        size: size,
        sortBy: 'entryDateTime',
        direction: 'DESC',
      );

      bool pastMonth = false;
      for (final trade in response.data) {
        final entry = trade.entryDateTime.toLocal();

        if (!entry.isBefore(monthEnd)) {
          // Newer than the requested month -- still paging toward it.
          continue;
        }
        if (entry.isBefore(monthStart)) {
          // Sorted newest-first, so everything from here on is even
          // older than the month we want -- no point paging further.
          pastMonth = true;
          break;
        }
        result.add(trade);
      }

      if (pastMonth || response.last) break;
      page++;
    }

    return result;
  }

  /// Bounded, recent slice of trade history for dashboard-level analytics
  /// (win rate, profit factor, PnL by strategy/session, mistake-tag
  /// frequency -- see `TradeAnalyticsHelper`). Trades are continuously
  /// auto-imported via MT5 (see the lazy-loading pagination doc), so this
  /// deliberately caps how much it pulls instead of paging through the
  /// entire history the way getAll() would -- same bounded-paging shape as
  /// getForMonth(), just capped by trade count instead of a calendar
  /// month. Pages newest-first, so the result is always "the most recent
  /// [limit] trades", which is also the more useful window for a
  /// performance dashboard than all-time history would be.
  static Future<List<Trade>> getRecentForAnalytics({int limit = 500}) async {
    final List<Trade> result = [];
    int page = 0;
    const size = 100;

    while (result.length < limit) {
      final response = await searchPage(
        page: page,
        size: size,
        sortBy: 'entryDateTime',
        direction: 'DESC',
      );

      result.addAll(response.data);

      if (response.last) break;
      page++;
    }

    return result.length > limit ? result.sublist(0, limit) : result;
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
