import 'package:flutter/material.dart';

import '../../models/asset_model.dart';
import '../../services/asset_service.dart';

class AssetForm extends StatefulWidget {
  final VoidCallback onAssetCreated;

  const AssetForm({super.key, required this.onAssetCreated});

  @override
  State<AssetForm> createState() => _AssetFormState();
}

class _AssetFormState extends State<AssetForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();

  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await AssetApi.createAsset(
        name: _nameController.text.trim(),
        symbol: _symbolController.text.trim().toUpperCase(),
      );

      _nameController.clear();
      _symbolController.clear();

      widget.onAssetCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Asset Name'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _symbolController,
            decoration: const InputDecoration(labelText: 'Symbol'),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const CircularProgressIndicator()
                : const Text('Create Asset'),
          ),
        ],
      ),
    );
  }
}


class AssetSymbolsList extends StatefulWidget {
  const AssetSymbolsList({super.key});

  @override
  State<AssetSymbolsList> createState() => _AssetSymbolsListState();
}

class _AssetSymbolsListState extends State<AssetSymbolsList> {
  late Future<List<Asset>> _assetsFuture;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  void _loadAssets() {
    _assetsFuture = AssetApi.fetchAssets();
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

        return ListView.builder(
          itemCount: assets.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.account_balance),
              title: Text(assets[index].symbol),
              subtitle: Text(assets[index].name),
            );
          },
        );
      },
    );
  }
}


class AssetScreen extends StatefulWidget {
  const AssetScreen({super.key});

  @override
  State<AssetScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends State<AssetScreen> {
  final GlobalKey<_AssetSymbolsListState> _listKey = GlobalKey();

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
                _listKey.currentState?._loadAssets();
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Symbols',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: AssetSymbolsList(key: _listKey),
            ),
          ],
        ),
      ),
    );
  }
}
