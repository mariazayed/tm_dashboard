import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tm_dashboard/models/trade_model.dart';

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

  static Future<List<Trade>> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.tradeURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch trades');
    }

    final List data = jsonDecode(response.body);
    return Future.wait(data.map((e) => Trade.fromJson(e)).toList());
  }
}
