import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/paginated_response.dart';
import '../models/question_category_model.dart';

class QuestionCategoryService {
  static Future<List<QuestionCategoryModel>> getAll() async {
    final response = await http.get(
      Uri.parse(ApiConstants.questionCategoriesURL),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch question categories');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => QuestionCategoryModel.fromJson(e)).toList();
  }

  static Future<QuestionCategoryModel> create(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ApiConstants.questionCategoriesURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create question category');
    }

    return QuestionCategoryModel.fromJson(jsonDecode(response.body));
  }

  static Future<QuestionCategoryModel> update(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.questionCategoriesURL}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update question category');
    }

    return QuestionCategoryModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> delete(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.questionCategoriesURL}/$id'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete question category');
    }
  }

  static Future<PaginatedResponse<QuestionCategoryModel>> searchPage({
    required int page,
    int size = 30,
    String sortBy = 'name',
    String direction = 'ASC',
  }) {
    return fetchSearchPage<QuestionCategoryModel>(
      '${ApiConstants.questionCategoriesURL}/search',
      (json) => QuestionCategoryModel.fromJson(json),
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
    );
  }

  static Future<List<QuestionCategoryModel>> getAllPaged() {
    return fetchAllPages<QuestionCategoryModel>(
      '${ApiConstants.questionCategoriesURL}/search',
      (json) => QuestionCategoryModel.fromJson(json),
      sortBy: 'name',
      direction: 'ASC',
    );
  }
}
