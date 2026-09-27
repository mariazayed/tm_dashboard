import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/static_data.dart';
import 'api_client.dart';

class StaticDataService {
  static http.Response? _response;
  static StaticDataResponse? _data;

  static Future<StaticDataResponse> getAll() async {
    final response = await ApiClient.shared.get(
      Uri.parse(ApiConstants.staticDataURL),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch static data');
    }
    // Reuse parsed lookup models only while the transport entry is current.
    if (!identical(response, _response)) {
      _data = StaticDataResponse.fromJson(jsonDecode(response.body));
      _response = response;
    }
    return _data!;
  }
}
