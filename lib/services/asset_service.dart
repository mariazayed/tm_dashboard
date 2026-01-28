import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tm_dashboard/constants/api_constants.dart';

import '../models/asset_model.dart';

class AssetApi {
  /// Create asset
  static Future<void> createAsset({
    required String name,
    required String symbol,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.assetURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'symbol': symbol,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create asset');
    }
  }

  /// Fetch all assets
  static Future<List<Asset>> fetchAssets() async {
    final response = await http.get(Uri.parse(ApiConstants.assetURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch assets');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => Asset.fromJson(e)).toList();
  }
}
