import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/goal_model.dart';
import '../models/paginated_response.dart';

class GoalService {
  static Future<List<GoalModel>> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.goalURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch goals');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => GoalModel.fromJson(e)).toList();
  }

  static Future<void> create(List<Map<String, dynamic>> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.goalURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create goal');
    }
  }

  static Future<GoalModel> update(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.goalURL}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update goal');
    }

    return GoalModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> delete(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.goalURL}/$id'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete goal');
    }
  }

  /// Paginated fetch backing the Goals screen, added mainly for consistency
  /// with the other list screens (goal counts are typically small).
  static Future<PaginatedResponse<GoalModel>> searchPage({
    required int page,
    int size = 30,
    String sortBy = 'createdAt',
    String direction = 'DESC',
  }) {
    return fetchSearchPage<GoalModel>(
      '${ApiConstants.goalURL}/search',
      (json) => GoalModel.fromJson(json),
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
    );
  }

  /// Drop-in replacement for [getAll] that fetches the same full list, but
  /// a page at a time under the hood via [searchPage]/[fetchAllPages]
  /// instead of one unbounded GET.
  static Future<List<GoalModel>> getAllPaged() {
    return fetchAllPages<GoalModel>(
      '${ApiConstants.goalURL}/search',
      (json) => GoalModel.fromJson(json),
      sortBy: 'createdAt',
      direction: 'DESC',
    );
  }
}
