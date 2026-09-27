import 'dart:convert';

import 'api_client.dart';

import '../constants/api_constants.dart';
import '../models/paginated_response.dart';
import '../models/question_answer_model.dart';

class QuestionAnswerService {
  static Future<List<QuestionAnswerModel>> getAll() async {
    final response = await ApiClient.shared.get(Uri.parse(ApiConstants.questionAnswersURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch questions and answers');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => QuestionAnswerModel.fromJson(e)).toList();
  }

  static Future<void> create(List<Map<String, dynamic>> data) async {
    final response = await ApiClient.shared.post(
      Uri.parse(ApiConstants.questionAnswersURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create question and answer');
    }
  }

  static Future<QuestionAnswerModel> update(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await ApiClient.shared.put(
      Uri.parse('${ApiConstants.questionAnswersURL}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update question and answer');
    }

    return QuestionAnswerModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> delete(int id) async {
    final response = await ApiClient.shared.delete(
      Uri.parse('${ApiConstants.questionAnswersURL}/$id'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete question and answer');
    }
  }

  static Future<PaginatedResponse<QuestionAnswerModel>> searchPage({
    required int page,
    int size = 30,
    String sortBy = 'updatedAt',
    String direction = 'DESC',
  }) {
    return fetchSearchPage<QuestionAnswerModel>(
      '${ApiConstants.questionAnswersURL}/search',
      (json) => QuestionAnswerModel.fromJson(json),
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
    );
  }

  static Future<List<QuestionAnswerModel>> getAllPaged() {
    return fetchAllPages<QuestionAnswerModel>(
      '${ApiConstants.questionAnswersURL}/search',
      (json) => QuestionAnswerModel.fromJson(json),
      sortBy: 'updatedAt',
      direction: 'DESC',
    );
  }
}
