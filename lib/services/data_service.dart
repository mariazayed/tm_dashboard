import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/static_data.dart';

class DataService {
  Future<StaticDataResponse> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.staticDataURL));

    if (response.statusCode == 200) {
      dynamic data = jsonDecode(response.body);
      return StaticDataResponse.fromJson(data);
    } else {
      throw Exception(
        'Failed to fetch StaticDataResponse: ${response.statusCode}',
      );
    }
  }
}
