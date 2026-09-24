import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/static_data.dart';

class StaticDataService {
  static StaticDataResponse? _data;
  static Future<StaticDataResponse>? _pending;

  static Future<StaticDataResponse> getAll() {
    if (_data != null) return Future.value(_data!);
    return _pending ??= _fetch();
  }

  static Future<StaticDataResponse> _fetch() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.staticDataURL));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch static data');
      }

      final data = jsonDecode(response.body);
      _data = StaticDataResponse.fromJson(data);

      return _data!;
    } finally {
      _pending = null;
    }
  }
}
