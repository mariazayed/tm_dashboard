import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/day_model.dart';

class DayService {
  Future<List<DayModel>> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.dayURL));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((dataObj) => DayModel.fromJson(dataObj)).toList();
    } else {
      throw Exception('Failed to fetch days: ${response.statusCode}');
    }
  }

  Future<DayModel> create(Object object) async {
    final response = await http.post(
      Uri.parse(ApiConstants.dayURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(object),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return DayModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create day: ${response.statusCode}');
    }
  }

  Future<DayModel> update(int id, Object requestObj) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.dayURL}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestObj),
    );

    if (response.statusCode == 200) {
      return DayModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update day: ${response.statusCode}');
    }
  }
}
