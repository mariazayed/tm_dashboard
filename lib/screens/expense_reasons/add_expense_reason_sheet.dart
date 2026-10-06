import 'package:flutter/material.dart';

import '../../models/expense_reason_model.dart';
import '../../services/expense_reason_service.dart';
import '../../theme/app_theme.dart';

/// Create/edit bottom sheet for a single expense reason -- same shape as
/// AddAssetSheet, just a single name field.
class AddExpenseReasonSheet extends StatefulWidget {
  final ExpenseReasonModel? existing;

  const AddExpenseReasonSheet({super.key, this.existing});

  @override
  State<AddExpenseReasonSheet> createState() => _AddExpenseReasonSheetState();
}

class _AddExpenseReasonSheetState extends State<AddExpenseReasonSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final name = _nameController.text.trim();

    try {
      if (_isEdit) {
        await ExpenseReasonService.update(widget.existing!.id, name);
      } else {
        await ExpenseReasonService.create(name);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save expense reason: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                  _isEdit ? 'Edit Expense Reason' : 'New Expense Reason',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Reason name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Text(_isEdit ? 'Save Changes' : 'Add Reason'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
