import 'dart:convert';

import 'api_client.dart';

import '../constants/api_constants.dart';
import '../models/expense_model.dart';
import '../models/paginated_response.dart';

class ExpenseService {
  static Future<ExpenseModel> create(Map<String, dynamic> data) async {
    final response = await ApiClient.shared.post(
      Uri.parse(ApiConstants.expenseURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create expense');
    }

    return ExpenseModel.fromJson(jsonDecode(response.body));
  }

  static Future<ExpenseModel> update(int id, Map<String, dynamic> data) async {
    final response = await ApiClient.shared.put(
      Uri.parse('${ApiConstants.expenseURL}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update expense');
    }

    return ExpenseModel.fromJson(jsonDecode(response.body));
  }

  /// Soft-deletes an expense (backend sets deletedAt rather than removing
  /// the row).
  static Future<void> delete(int id) async {
    final response = await ApiClient.shared.delete(
      Uri.parse('${ApiConstants.expenseURL}/$id'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete expense');
    }
  }

  static Future<List<ExpenseModel>> fetchAll() async {
    final response = await ApiClient.shared.get(Uri.parse(ApiConstants.expenseURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch expenses');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => ExpenseModel.fromJson(e)).toList();
  }

  static Future<PaginatedResponse<ExpenseModel>> searchPage({
    required int page,
    int size = 30,
    String sortBy = 'date',
    String direction = 'DESC',
  }) {
    return fetchSearchPage<ExpenseModel>(
      '${ApiConstants.expenseURL}/search',
      (json) => ExpenseModel.fromJson(json),
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
    );
  }

  /// Drop-in replacement for [fetchAll] that fetches the same full list, but
  /// a page at a time under the hood via [searchPage]/[fetchAllPages]
  /// instead of one unbounded GET -- same pattern as Assets/Goals.
  static Future<List<ExpenseModel>> fetchAllPaged() {
    return fetchAllPages<ExpenseModel>(
      '${ApiConstants.expenseURL}/search',
      (json) => ExpenseModel.fromJson(json),
      sortBy: 'date',
      direction: 'DESC',
    );
  }
}
