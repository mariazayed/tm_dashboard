import 'package:flutter/material.dart';

import 'asset_form.dart';
import 'assets_list.dart';

class AssetScreen extends StatefulWidget {
  const AssetScreen({super.key});

  @override
  State<AssetScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends State<AssetScreen> {
  final GlobalKey<AssetsListState> _listKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assets')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AssetForm(
              onAssetCreated: () {
                _listKey.currentState?.loadAssets();
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Symbols',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: AssetsList(key: _listKey),
            ),
          ],
        ),
      ),
    );
  }
}
