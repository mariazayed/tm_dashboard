import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class TradeService {
  static Future<void> create(List<dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.tradeURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create trades');
    }
  }
}
