import 'dart:convert';

import 'api_client.dart';

import '../constants/api_constants.dart';
import '../models/expense_reason_model.dart';
import '../models/paginated_response.dart';

class ExpenseReasonService {
  static Future<ExpenseReasonModel> create(String name) async {
    final response = await ApiClient.shared.post(
      Uri.parse(ApiConstants.expenseReasonURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create expense reason');
    }

    return ExpenseReasonModel.fromJson(jsonDecode(response.body));
  }

  static Future<ExpenseReasonModel> update(int id, String name) async {
    final response = await ApiClient.shared.put(
      Uri.parse('${ApiConstants.expenseReasonURL}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update expense reason');
    }

    return ExpenseReasonModel.fromJson(jsonDecode(response.body));
  }

  /// Soft-deletes a reason. Existing expenses keep showing it -- it just
  /// drops out of the picker for new/edited expenses.
  static Future<void> delete(int id) async {
    final response = await ApiClient.shared.delete(
      Uri.parse('${ApiConstants.expenseReasonURL}/$id'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete expense reason');
    }
  }

  static Future<List<ExpenseReasonModel>> fetchAll() async {
    final response = await ApiClient.shared.get(Uri.parse(ApiConstants.expenseReasonURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch expense reasons');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => ExpenseReasonModel.fromJson(e)).toList();
  }

  /// Paginated fetch, added mainly for consistency with the other list
  /// screens (reason counts are typically small).
  static Future<PaginatedResponse<ExpenseReasonModel>> searchPage({
    required int page,
    int size = 30,
    String sortBy = 'name',
    String direction = 'ASC',
  }) {
    return fetchSearchPage<ExpenseReasonModel>(
      '${ApiConstants.expenseReasonURL}/search',
      (json) => ExpenseReasonModel.fromJson(json),
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
    );
  }

  /// Fetches the full reason list a page at a time under the hood. Used by
  /// both the dedicated Expense Reasons screen and the inline reason picker
  /// opened from the Add Expense sheet.
  static Future<List<ExpenseReasonModel>> fetchAllPaged() {
    return fetchAllPages<ExpenseReasonModel>(
      '${ApiConstants.expenseReasonURL}/search',
      (json) => ExpenseReasonModel.fromJson(json),
      sortBy: 'name',
      direction: 'ASC',
    );
  }
}
