import 'package:flutter/material.dart';

import '../../models/asset_model.dart';
import '../../services/api_client.dart';
import '../../services/asset_service.dart';
import '../../theme/app_theme.dart';
import 'add_asset_sheet.dart';
import 'asset_card.dart';

class AssetScreen extends StatefulWidget {
  const AssetScreen({super.key});

  @override
  State<AssetScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends State<AssetScreen> {
  late Future<List<Asset>> _future;
  String _query = '';

  // Asset ids with a delete request currently in flight -- passed to
  // AssetCard as `busy` so a card shows a spinner instead of silently doing
  // nothing if its menu is tapped again mid-request. Same pattern as
  // GoalsScreen's _pendingGoalIds.
  final Set<String> _pendingAssetIds = {};

  @override
  void initState() {
    super.initState();
    // Paged transport under the hood (AssetService.fetchAssetsPaged ->
    // .../asset/search) instead of one unbounded GET.
    _future = AssetService.fetchAssetsPaged();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = AssetService.fetchAssetsPaged();
    });
    try {
      await _future;
    } catch (_) {
      // The FutureBuilder displays the load error.
    }
  }

  Future<void> _openAddAsset({Asset? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAssetSheet(existing: existing),
    );
    _refresh();
  }

  Future<void> _confirmDelete(Asset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete asset'),
        content: Text(
          'Delete "${asset.symbol}"? Existing trades keep their history, but this cannot be undone here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _pendingAssetIds.add(asset.id));
    try {
      await AssetService.deleteAsset(asset.id);
      _refresh();
    } catch (e) {
      if (mounted) {
        setState(() => _pendingAssetIds.remove(asset.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete asset: $e')),
        );
      }
      return;
    }
    // On success _refresh() replaces `future` with a new fetch, which
    // rebuilds fresh AssetCards anyway -- but clear it in case the fetch
    // fails and the old cards (still showing this asset) get reused.
    if (mounted) setState(() => _pendingAssetIds.remove(asset.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openAddAsset(),
          ),
        ],
      ),
      body: FutureBuilder<List<Asset>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load assets:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final colorScheme = Theme.of(context).colorScheme;
          final assets = snapshot.data ?? [];
          final filtered = _query.trim().isEmpty
              ? assets
              : assets.where((a) {
                  final q = _query.trim().toLowerCase();
                  return a.symbol.toLowerCase().contains(q) ||
                      a.name.toLowerCase().contains(q);
                }).toList();

          return RefreshIndicator(
            onRefresh: () => ApiClient.shared.refresh(_refresh),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by symbol or name…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${filtered.length} asset${filtered.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: colorScheme.outlineVariant),
                          const SizedBox(height: 12),
                          Text(
                            assets.isEmpty
                                ? 'No assets yet — add your first symbol'
                                : 'No assets match your search',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildGrid(filtered),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<Asset> assets) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 320).floor().clamp(1, 3).toInt();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: assets.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 132,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (_, i) => AssetCard(
            asset: assets[i],
            busy: _pendingAssetIds.contains(assets[i].id),
            onEdit: () => _openAddAsset(existing: assets[i]),
            onDelete: () => _confirmDelete(assets[i]),
          ),
        );
      },
    );
  }
}
