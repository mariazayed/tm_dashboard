import 'package:flutter/material.dart';

import '../../models/expense_reason_model.dart';
import '../../services/api_client.dart';
import '../../services/expense_reason_service.dart';
import '../../theme/app_theme.dart';
import 'add_expense_reason_sheet.dart';
import 'expense_reason_card.dart';

/// Dedicated full-CRUD page for the expense-reason lookup options: see all,
/// add, update, delete. Mirrors AssetScreen's structure (search + grid +
/// pending-id spinner) since a reason is just as simple a lookup as an
/// asset.
class ExpenseReasonsScreen extends StatefulWidget {
  const ExpenseReasonsScreen({super.key});

  @override
  State<ExpenseReasonsScreen> createState() => _ExpenseReasonsScreenState();
}

class _ExpenseReasonsScreenState extends State<ExpenseReasonsScreen> {
  late Future<List<ExpenseReasonModel>> _future;
  String _query = '';

  final Set<int> _pendingIds = {};

  @override
  void initState() {
    super.initState();
    _future = ExpenseReasonService.fetchAllPaged();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ExpenseReasonService.fetchAllPaged();
    });
    try {
      await _future;
    } catch (_) {
      // The FutureBuilder displays the load error.
    }
  }

  Future<void> _openAdd({ExpenseReasonModel? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseReasonSheet(existing: existing),
    );
    _refresh();
  }

  Future<void> _confirmDelete(ExpenseReasonModel reason) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete expense reason'),
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
        setState(() => _pendingIds.remove(reason.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete expense reason: $e')),
        );
      }
      return;
    }
    if (mounted) setState(() => _pendingIds.remove(reason.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Reasons'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openAdd()),
        ],
      ),
      body: FutureBuilder<List<ExpenseReasonModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load expense reasons:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final colorScheme = Theme.of(context).colorScheme;
          final reasons = snapshot.data ?? [];
          final filtered = _query.trim().isEmpty
              ? reasons
              : reasons
                  .where((r) => r.name.toLowerCase().contains(_query.trim().toLowerCase()))
                  .toList();

          return RefreshIndicator(
            onRefresh: () => ApiClient.shared.refresh(_refresh),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search reasons…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${filtered.length} reason${filtered.length == 1 ? '' : 's'}',
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
                          Icon(Icons.receipt_long_outlined, size: 48, color: colorScheme.outlineVariant),
                          const SizedBox(height: 12),
                          Text(
                            reasons.isEmpty
                                ? 'No expense reasons yet — add your first one'
                                : 'No reasons match your search',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ExpenseReasonCard(
                        reason: r,
                        busy: _pendingIds.contains(r.id),
                        onEdit: () => _openAdd(existing: r),
                        onDelete: () => _confirmDelete(r),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
