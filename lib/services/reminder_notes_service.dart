import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tm_dashboard/models/trade_model.dart';

import '../constants/api_constants.dart';
import '../models/paginated_response.dart';
import '../models/reminder_note_model.dart';

class ReminderNotesService {
  static Future<void> create(List<dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.reminderNotesURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create reminder notes');
    }
  }

  static Future<List<ReminderNoteModel>> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.reminderNotesURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch reminder notes');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => ReminderNoteModel.fromJson(e)).toList();
  }

  static Future<void> delete(int id) async {
    final response = await http.delete(Uri.parse("${ApiConstants.reminderNotesURL}/$id"));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete reminder notes');
    }

    return;
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
