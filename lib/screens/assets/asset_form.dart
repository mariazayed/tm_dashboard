import 'package:flutter/material.dart';

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
      await AssetService.createAsset(
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