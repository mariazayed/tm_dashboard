import 'package:flutter/material.dart';

import '../../models/asset_model.dart';
import '../../services/asset_service.dart';

class AssetsList extends StatefulWidget {
  const AssetsList({super.key});

  @override
  State<AssetsList> createState() => AssetsListState();
}

class AssetsListState extends State<AssetsList> {
  late Future<List<Asset>> _assetsFuture;

  @override
  void initState() {
    super.initState();
    loadAssets();
  }

  void loadAssets() {
    // Paged transport under the hood (AssetService.fetchAssetsPaged ->
    // .../asset/search) instead of one unbounded GET -- this standalone
    // Assets list screen shows its own data, unlike the filter dropdowns
    // elsewhere (trade list/journal) which keep using fetchAssets() since
    // they need the complete option set loaded in one go.
    _assetsFuture = AssetService.fetchAssetsPaged();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Asset>>(
      future: _assetsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        final assets = snapshot.data!;

        return ListView.separated(
          itemCount: assets.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final asset = assets[index];

            return ListTile(
              leading: CircleAvatar(
                child: Text(asset.id),
              ),
              title: Text(
                asset.symbol,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'ID: ${asset.id} • ${asset.name}',
              ),
            );
          },
        );
      },
    );
  }
}