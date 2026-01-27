import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/memoir_model.dart';
import '../models/static_data.dart';

class MemoirService {
  Future<List<MemoirModel>> getAll() async {
    final response = await http.get(Uri.parse(ApiConstants.memoirURL));

    if (response.statusCode == 200) {
      dynamic data = jsonDecode(response.body);
      return data.map((dataObj) => MemoirModel.fromJson(dataObj)).toList();
    } else {
      throw Exception(
        'Failed to fetch all memoirs: ${response.statusCode}',
      );
    }
  }

  Future<MemoirModel> create(Object object) async {
    final response = await http.post(
      Uri.parse(ApiConstants.memoirURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(object),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return MemoirModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create memoir: ${response.statusCode}');
    }
  }

  Future<MemoirModel> update(int id, Object requestObj) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.memoirURL}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestObj),
    );

    if (response.statusCode == 200) {
      return MemoirModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update memoir: ${response.statusCode}');
    }
  }
}
