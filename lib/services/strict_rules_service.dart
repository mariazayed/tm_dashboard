import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
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
}
