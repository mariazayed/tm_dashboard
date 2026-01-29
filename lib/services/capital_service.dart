import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tm_dashboard/models/capital_model.dart';
import 'package:tm_dashboard/models/trade_model.dart';

import '../constants/api_constants.dart';

class CapitalService {
  static Future<void> create(List<dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.capitalURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create capitals');
    }
  }

  static Future<List<CapitalModel>> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.capitalURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch capitals');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => CapitalModel.fromJson(e)).toList();
  }
}
