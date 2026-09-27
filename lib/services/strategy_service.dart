import 'dart:convert';

import 'api_client.dart';

import '../constants/api_constants.dart';
import '../models/paginated_response.dart';
import '../models/strategy_model.dart';

class StrategyService {
  static Future<void> create(List<dynamic> data) async {
    final response = await ApiClient.shared.post(
      Uri.parse(ApiConstants.strategyURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create strategies');
    }
  }

  static Future<List<Strategy>> getAll() async {
    final response = await ApiClient.shared.get(Uri.parse(ApiConstants.strategyURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch strategies');
    }

    final List data = jsonDecode(response.body);

    return Future.wait(data.map((e) => Strategy.fromJson(e)));
  }

  /// Paginated fetch, added mainly for consistency with the other list
  /// screens (strategy counts are typically small).
  static Future<PaginatedResponse<Strategy>> searchPage({
    required int page,
    int size = 30,
    String sortBy = 'id',
    String direction = 'DESC',
  }) {
    return fetchSearchPage<Strategy>(
      '${ApiConstants.strategyURL}/search',
      (json) => Strategy.fromJson(json),
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
    );
  }

  /// Drop-in replacement for [getAll] that fetches the same full list, but
  /// a page at a time under the hood via [searchPage]/[fetchAllPages]
  /// instead of one unbounded GET.
  static Future<List<Strategy>> getAllPaged() {
    return fetchAllPages<Strategy>(
      '${ApiConstants.strategyURL}/search',
      (json) => Strategy.fromJson(json),
      sortBy: 'id',
      direction: 'DESC',
    );
  }
}
