import 'package:flutter/material.dart';

import '../../models/expense_reason_model.dart';
import '../../services/expense_reason_service.dart';

/// Bottom sheet used by AddExpenseSheet to pick the expense reason. Per the
/// user's request, this isn't a plain dropdown: each option row carries its
/// own edit/delete icons (renaming or soft-deleting right from here), and
/// there's an inline "add new reason" field at the bottom -- so the reason
/// list can be fully managed without leaving the Add Expense flow, in
/// addition to the dedicated Expense Reasons page for the same thing.
///
/// Pops with the selected [ExpenseReasonModel], or null if dismissed without
/// picking one.
class ExpenseReasonPickerSheet extends StatefulWidget {
  final int? selectedId;

  const ExpenseReasonPickerSheet({super.key, this.selectedId});

  @override
  State<ExpenseReasonPickerSheet> createState() => _ExpenseReasonPickerSheetState();
}

class _ExpenseReasonPickerSheetState extends State<ExpenseReasonPickerSheet> {
  late Future<List<ExpenseReasonModel>> _future;
  final Set<int> _pendingIds = {};
  final _newReasonController = TextEditingController();
  bool _addingReason = false;

  @override
  void initState() {
    super.initState();
    _future = ExpenseReasonService.fetchAllPaged();
  }

  @override
  void dispose() {
    _newReasonController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() => _future = ExpenseReasonService.fetchAllPaged());
  }

  Future<void> _addReason() async {
    final name = _newReasonController.text.trim();
    if (name.isEmpty) return;

    setState(() => _addingReason = true);
    try {
      final created = await ExpenseReasonService.create(name);
      _newReasonController.clear();
      _refresh();
      // Auto-select the reason the user just typed -- saves a second tap.
      if (mounted) Navigator.pop(context, created);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add reason: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _addingReason = false);
    }
  }

  Future<void> _editReason(ExpenseReasonModel reason) async {
    final controller = TextEditingController(text: reason.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename reason'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Reason name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == reason.name) return;

    setState(() => _pendingIds.add(reason.id));
    try {
      await ExpenseReasonService.update(reason.id, newName);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rename reason: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pendingIds.remove(reason.id));
    }
  }

  Future<void> _deleteReason(ExpenseReasonModel reason) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete reason'),
        content: Text(
          'Delete "${reason.name}"? Past expenses keep showing it, but it will no longer be offered for new ones.',
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

    setState(() => _pendingIds.add(reason.id));
    try {
      await ExpenseReasonService.delete(reason.id);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete reason: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pendingIds.remove(reason.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Select Reason',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<ExpenseReasonModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Failed to load reasons: ${snapshot.error}'));
                    }

                    final reasons = snapshot.data ?? [];
                    if (reasons.isEmpty) {
                      return Center(
                        child: Text(
                          'No reasons yet — add one below',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: reasons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final reason = reasons[i];
                        final busy = _pendingIds.contains(reason.id);
                        final selected = reason.id == widget.selectedId;

                        return Opacity(
                          opacity: busy ? 0.5 : 1,
                          child: Material(
                            color: selected
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: busy ? null : () => Navigator.pop(context, reason),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: Row(
                                  children: [
                                    if (selected)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Icon(
                                          Icons.check_circle,
                                          size: 18,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        reason.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    if (busy)
                                      const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                    else ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        tooltip: 'Edit',
                                        onPressed: () => _editReason(reason),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        tooltip: 'Delete',
                                        onPressed: () => _deleteReason(reason),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newReasonController,
                      decoration: const InputDecoration(hintText: 'Add new reason…'),
                      onSubmitted: (_) => _addReason(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addingReason ? null : _addReason,
                    icon: _addingReason
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
