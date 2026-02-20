import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/static_data.dart';

class StaticDataService {
  static StaticDataResponse? _data;

  static Future<StaticDataResponse> getAll() async {
    if (StaticDataService._data != null) {
      return StaticDataService._data!;
    }

    final response = await http.get(Uri.parse(ApiConstants.staticDataURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch static data');
    }

    final data = jsonDecode(response.body);
    StaticDataService._data = StaticDataResponse.fromJson(data);

    return StaticDataService._data!;
  }
}
