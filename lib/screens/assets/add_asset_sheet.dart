import 'package:flutter/material.dart';

import '../../models/asset_model.dart';
import '../../services/asset_service.dart';
import '../../widgets/form_number_field.dart';

class AddAssetSheet extends StatefulWidget {
  final Asset? existing;

  const AddAssetSheet({super.key, this.existing});

  @override
  State<AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends State<AddAssetSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _symbolController;
  late TextEditingController _contractSizeController;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _symbolController = TextEditingController(text: existing?.symbol ?? '');
    _contractSizeController = TextEditingController(
      text: existing?.contractSize != null ? _trimZeros(existing!.contractSize!) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _contractSizeController.dispose();
    super.dispose();
  }

  String _trimZeros(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final symbol = _symbolController.text.trim().toUpperCase();
    final contractSizeText = _contractSizeController.text.trim();
    final contractSize = contractSizeText.isEmpty ? null : double.tryParse(contractSizeText);

    try {
      if (_isEdit) {
        await AssetService.updateAsset(widget.existing!.id, {
          'name': name,
          'symbol': symbol,
          'contractSize': contractSize,
        });
      } else {
        await AssetService.createAsset(
          name: name,
          symbol: symbol,
          contractSize: contractSize,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save asset: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Text(
                  _isEdit ? 'Edit Asset' : 'New Asset',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Asset name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _symbolController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Symbol'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            FormNumberField(
              label: 'Contract size per lot (optional)',
              controller: _contractSizeController,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEdit ? 'Save Changes' : 'Create Asset'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
