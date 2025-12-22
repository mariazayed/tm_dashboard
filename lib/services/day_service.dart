import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/day_model.dart';

class DayService {
  Future<List<DayModel>> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.dayURL));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final result = data.map((asset) => DayModel.fromJson(asset)).toList();
      print('result $result');
      return result;
    } else {
      throw Exception('Failed to fetch days: ${response.statusCode}');
    }
  }
}
