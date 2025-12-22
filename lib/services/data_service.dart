import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/static_data.dart';

class DataService {
  Future<List<StaticDataResponse>> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.staticDataURL));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((dataObj) => StaticDataResponse.fromJson(dataObj))
          .toList();
    } else {
      throw Exception(
        'Failed to fetch StaticDataResponse: ${response.statusCode}',
      );
    }
  }
}
