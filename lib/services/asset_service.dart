import 'dart:convert';
import 'api_client.dart';
import 'package:tm_dashboard/constants/api_constants.dart';

import '../models/asset_model.dart';
import '../models/paginated_response.dart';

class AssetService {
  /// Create asset
  static Future<void> createAsset({
    required String name,
    required String symbol,
    double? contractSize,
    double? pipSize,
  }) async {
    final response = await ApiClient.shared.post(
      Uri.parse(ApiConstants.assetURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'symbol': symbol,
        'contractSize': contractSize,
        'pipSize': pipSize,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create asset');
    }
  }

  /// Update asset. Mirrors GoalService.update -- backend's UpdateAssetRequest
  /// only touches fields that are non-null in [data], so a partial map is
  /// fine, but the edit sheet always sends the full set anyway.
  static Future<Asset> updateAsset(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.shared.put(
      Uri.parse('${ApiConstants.assetURL}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update asset');
    }

    return Asset.fromJson(jsonDecode(response.body));
  }

  /// Soft-deletes an asset (AssetController.deleteAsset -> AssetService.delete
  /// on the backend sets deletedAt rather than removing the row).
  static Future<void> deleteAsset(String id) async {
    final response = await ApiClient.shared.delete(
      Uri.parse('${ApiConstants.assetURL}/$id'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete asset');
    }
  }

  /// Fetch all assets
  static Future<List<Asset>> fetchAssets() async {
    final response = await ApiClient.shared.get(Uri.parse(ApiConstants.assetURL));

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
