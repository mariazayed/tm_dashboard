import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tm_dashboard/constants/api_constants.dart';

import '../models/asset_model.dart';
import '../models/paginated_response.dart';

class AssetService {
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

  /// Paginated fetch, added mainly for consistency with the other list
  /// screens (asset counts are typically small). tm-server's AssetController
  /// already exposed POST /asset/search before this change.
  static Future<PaginatedResponse<Asset>> searchPage({
    required int page,
    int size = 30,
    String sortBy = 'id',
    String direction = 'ASC',
  }) {
    return fetchSearchPage<Asset>(
      '${ApiConstants.assetURL}/search',
      (json) => Asset.fromJson(json),
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
    );
  }

  /// Drop-in replacement for [fetchAssets] that fetches the same full list,
  /// but a page at a time under the hood via [searchPage]/[fetchAllPages]
  /// instead of one unbounded GET. Intended for the standalone Assets list
  /// screen -- filter dropdowns elsewhere (trade list/journal) should keep
  /// using [fetchAssets] since they need the complete option set loaded in
  /// one go regardless of list size.
  static Future<List<Asset>> fetchAssetsPaged() {
    return fetchAllPages<Asset>(
      '${ApiConstants.assetURL}/search',
      (json) => Asset.fromJson(json),
      sortBy: 'id',
      direction: 'ASC',
    );
  }
}
