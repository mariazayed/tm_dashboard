import 'dart:convert';

import 'api_client.dart';
import '../constants/api_constants.dart';
import '../models/paginated_response.dart';
import '../models/reminder_note_model.dart';
import '../models/reminder_note_category_model.dart';

class ReminderNotesService {
  static Future<void> create(List<dynamic> data) async {
    final response = await ApiClient.shared.post(
      Uri.parse(ApiConstants.reminderNotesURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create reminder notes');
    }
  }

  static Future<List<ReminderNoteModel>> getAll() async {
    final response = await ApiClient.shared.get(
      Uri.parse(ApiConstants.reminderNotesURL),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch reminder notes');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => ReminderNoteModel.fromJson(e)).toList();
  }

  static Future<void> delete(int id) async {
    final response = await ApiClient.shared.delete(
      Uri.parse("${ApiConstants.reminderNotesURL}/$id"),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete reminder notes');
    }

    return;
  }

  static Future<List<ReminderNoteCategoryModel>> getCategories() async {
    final response = await ApiClient.shared.get(
      Uri.parse(ApiConstants.reminderNoteCategoriesURL),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load note categories');
    }
    final List data = jsonDecode(response.body);
    return data.map((e) => ReminderNoteCategoryModel.fromJson(e)).toList();
  }

  static Future<ReminderNoteCategoryModel> createCategory(String name) async {
    final response = await ApiClient.shared.post(
      Uri.parse(ApiConstants.reminderNoteCategoriesURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create category');
    }
    return ReminderNoteCategoryModel.fromJson(jsonDecode(response.body));
  }

  static Future<ReminderNoteCategoryModel> updateCategory(
    int id,
    String name,
  ) async {
    final response = await ApiClient.shared.put(
      Uri.parse('${ApiConstants.reminderNoteCategoriesURL}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update category');
    }
    return ReminderNoteCategoryModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> deleteCategory(int id) async {
    final response = await ApiClient.shared.delete(
      Uri.parse('${ApiConstants.reminderNoteCategoriesURL}/$id'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete category');
    }
  }

  /// Paginated fetch, added mainly for consistency with the other list
  /// screens (reminder-note counts are typically small).
  static Future<PaginatedResponse<ReminderNoteModel>> searchPage({
    required int page,
    int size = 30,
    String sortBy = 'id',
    String direction = 'DESC',
  }) {
    return fetchSearchPage<ReminderNoteModel>(
      '${ApiConstants.reminderNotesURL}/search',
      (json) => ReminderNoteModel.fromJson(json),
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
    );
  }

  /// Drop-in replacement for [getAll] that fetches the same full list, but
  /// a page at a time under the hood via [searchPage]/[fetchAllPages]
  /// instead of one unbounded GET.
  static Future<List<ReminderNoteModel>> getAllPaged() {
    return fetchAllPages<ReminderNoteModel>(
      '${ApiConstants.reminderNotesURL}/search',
      (json) => ReminderNoteModel.fromJson(json),
      sortBy: 'id',
      direction: 'DESC',
    );
  }
}
