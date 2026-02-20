import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/strategy_model.dart';

class StrategyService {
  static Future<void> create(List<dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.strategyURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create strategies');
    }
  }

  static Future<List<StrategyModel>> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.strategyURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch strategies');
    }

    final List data = jsonDecode(response.body);

    return Future.wait(data.map((e) => StrategyModel.fromJson(e)));
  }
}
