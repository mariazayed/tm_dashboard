import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/paginated_response.dart';
import '../models/strict_rule_model.dart';

class StrictRulesService {
  static Future<void> create(List<dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.strictRulesURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create strict rules');
    }
  }

  static Future<List<StrictRuleModel>> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.strictRulesURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch strict rules');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => StrictRuleModel.fromJson(e)).toList();
  }

  static Future<void> delete(int id) async {
    final response = await http.delete(
      Uri.parse("${ApiConstants.strictRulesURL}/$id"),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete strict rules');
    }

    return;
  }

  /// Paginated fetch, added mainly for consistency with the other list
  /// screens (strict-rule counts are typically small).
  static Future<PaginatedResponse<StrictRuleModel>> searchPage({
    required int page,
    int size = 30,
    String sortBy = 'id',
    String direction = 'DESC',
  }) {
    return fetchSearchPage<StrictRuleModel>(
      '${ApiConstants.strictRulesURL}/search',
      (json) => StrictRuleModel.fromJson(json),
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
    );
  }

  /// Drop-in replacement for [getAll] that fetches the same full list, but
  /// a page at a time under the hood via [searchPage]/[fetchAllPages]
  /// instead of one unbounded GET.
  static Future<List<StrictRuleModel>> getAllPaged() {
    return fetchAllPages<StrictRuleModel>(
      '${ApiConstants.strictRulesURL}/search',
      (json) => StrictRuleModel.fromJson(json),
      sortBy: 'id',
      direction: 'DESC',
    );
  }
}
