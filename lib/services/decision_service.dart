import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/decision_model.dart';
import '../models/paginated_response.dart';

class DecisionService {
  static Future<List<DecisionModel>> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.decisionURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch decisions');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => DecisionModel.fromJson(e)).toList();
  }

  static Future<void> create(List<Map<String, dynamic>> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.decisionURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create decision');
    }
  }

  static Future<DecisionModel> update(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.decisionURL}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update decision');
    }

    return DecisionModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> delete(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.decisionURL}/$id'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete decision');
    }
  }

  /// Paginated fetch backing the Decisions screen, added mainly for
  /// consistency with the other list screens.
  static Future<PaginatedResponse<DecisionModel>> searchPage({
    required int page,
    int size = 30,
    String sortBy = 'decisionDate',
    String direction = 'DESC',
  }) {
    return fetchSearchPage<DecisionModel>(
      '${ApiConstants.decisionURL}/search',
      (json) => DecisionModel.fromJson(json),
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
    );
  }

  /// Drop-in replacement for [getAll] that fetches the same full list, but
  /// a page at a time under the hood via [searchPage]/[fetchAllPages]
  /// instead of one unbounded GET.
  static Future<List<DecisionModel>> getAllPaged() {
    return fetchAllPages<DecisionModel>(
      '${ApiConstants.decisionURL}/search',
      (json) => DecisionModel.fromJson(json),
      sortBy: 'decisionDate',
      direction: 'DESC',
    );
  }
}
