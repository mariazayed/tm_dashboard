import 'dart:convert';

import 'api_client.dart';

import '../constants/api_constants.dart';
import '../models/memoir_model.dart';
import '../models/static_data.dart';

class MemoirService {
  Future<List<MemoirModel>> getAll() async {
    final response = await ApiClient.shared.get(Uri.parse(ApiConstants.memoirURL));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final List<MemoirModel> list = data
          .map((e) => MemoirModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } else {
      throw Exception(
        'Failed to fetch all memoirs: ${response.statusCode}',
      );
    }
  }

  Future<MemoirModel> create(Object object) async {
    final response = await ApiClient.shared.post(
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
    final response = await ApiClient.shared.put(
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
