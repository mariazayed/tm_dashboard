import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense_model.dart';
import '../../models/expense_reason_model.dart';
import '../../services/expense_service.dart';
import '../../widgets/form_number_field.dart';
import '../../widgets/form_text_area_field.dart';
import 'expense_reason_picker_sheet.dart';

class AddExpenseSheet extends StatefulWidget {
  final ExpenseModel? existing;

  const AddExpenseSheet({super.key, this.existing});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _date;
  ExpenseReasonModel? _reason;
  bool _saving = false;
  String? _reasonError;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _amountController = TextEditingController(
      text: existing != null ? _trimZeros(existing.amount) : '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _date = existing?.date ?? DateTime.now();
    _reason = existing?.expenseReason;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _trimZeros(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
      initialDate: _date,
    );
    if (picked == null) return;
    setState(() {
      // Keep the existing time-of-day, only replace the date part.
      _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute);
    });
  }

  Future<void> _pickReason() async {
    final selected = await showModalBottomSheet<ExpenseReasonModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseReasonPickerSheet(selectedId: _reason?.id),
    );
    if (selected != null) {
      setState(() {
        _reason = selected;
        _reasonError = null;
      });
    }
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();
    setState(() => _reasonError = _reason == null ? 'Select a reason' : null);

    final amount = double.tryParse(_amountController.text.trim());
    if (!formOk || _reason == null || amount == null || amount <= 0) {
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount greater than 0')),
        );
      }
      return;
    }

    setState(() => _saving = true);

    final notes = _notesController.text.trim();

    final draft = ExpenseModel(
      id: widget.existing?.id ?? 0,
      date: _date,
      amount: amount,
      expenseReason: _reason!,
      notes: notes.isEmpty ? null : notes,
    );

    try {
      // Pop with the server's saved copy (not the local `draft`) so the
      // caller can drop it straight into its list -- server-assigned id on
      // create, and the response is the source of truth either way -- for
      // an instant update with no extra round trip back to the list screen.
      final ExpenseModel saved;
      if (_isEdit) {
        saved = await ExpenseService.update(widget.existing!.id, draft.toUpdateJson());
      } else {
        saved = await ExpenseService.create(draft.toCreateJson());
      }

      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save expense: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');

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
                  _isEdit ? 'Edit Expense' : 'New Expense',
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
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('Date: ${fmt.format(_date)}'),
              ),
            ),
            const SizedBox(height: 12),
            FormNumberField(label: 'Amount (\$)', controller: _amountController),
            const SizedBox(height: 4),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickReason,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Reason',
                  errorText: _reasonError,
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _reason?.name ?? 'Select a reason…',
                  style: TextStyle(
                    color: _reason == null ? Colors.grey.shade500 : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FormTextAreaField(label: 'Notes (optional)', controller: _notesController),
            const SizedBox(height: 24),
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
                    : Text(_isEdit ? 'Save Changes' : 'Add Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
