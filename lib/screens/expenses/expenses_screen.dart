import 'package:flutter/material.dart';

import '../../models/expense_model.dart';
import '../../services/api_client.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';
import 'add_expense_sheet.dart';
import 'expense_card.dart';

/// Standalone expense log -- deliberately kept separate from Capital
/// (deposits/withdraws/trade P&L) and the Dashboard, per the user's choice:
/// this list and its total don't feed into either.
///
/// List state is held locally (`_expenses`) and mutated in place on
/// add/edit/delete instead of re-fetching the whole paginated list after
/// every action -- so the list and total update immediately, with no extra
/// round trip back to the server just to redisplay what was already
/// returned by the create/update/delete call itself.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<ExpenseModel>? _expenses; // null while the initial load is in flight
  Object? _loadError;
  String _query = '';

  final Set<int> _pendingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final data = await ExpenseService.fetchAllPaged();
      if (!mounted) return;
      setState(() => _expenses = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  // Inserts a new expense or replaces an edited one, then keeps the list in
  // the same newest-first order the initial load uses (fetchAllPaged sorts
  // by date DESC) -- so an edit that changes the date still lands in the
  // right spot instead of just staying wherever it was.
  void _upsertLocal(ExpenseModel expense) {
    setState(() {
      final list = [...?_expenses];
      final index = list.indexWhere((e) => e.id == expense.id);
      if (index >= 0) {
        list[index] = expense;
      } else {
        list.add(expense);
      }
      list.sort((a, b) => b.date.compareTo(a.date));
      _expenses = list;
    });
  }

  void _removeLocal(int id) {
    setState(() {
      _expenses = [...?_expenses]..removeWhere((e) => e.id == id);
    });
  }

  Future<void> _openAdd({ExpenseModel? existing}) async {
    final saved = await showModalBottomSheet<ExpenseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(existing: existing),
    );
    if (saved != null) _upsertLocal(saved);
  }

  Future<void> _confirmDelete(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete expense'),
        content: Text(
          'Delete this \$${expense.amount.toStringAsFixed(2)} expense (${expense.expenseReason.name})? This cannot be undone.',
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

    setState(() => _pendingIds.add(expense.id));
    try {
      await ExpenseService.delete(expense.id);
      _removeLocal(expense.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete expense: $e')),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _pendingIds.remove(expense.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openAdd()),
        ],
      ),
      body: Builder(
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;

          if (_expenses == null && _loadError == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_loadError != null && _expenses == null) {
            return Center(
              child: Text(
                'Failed to load expenses:\n$_loadError',
                textAlign: TextAlign.center,
              ),
            );
          }

          final expenses = _expenses ?? [];
          final filtered = _query.trim().isEmpty
              ? expenses
              : expenses.where((e) {
                  final q = _query.trim().toLowerCase();
                  return e.expenseReason.name.toLowerCase().contains(q) ||
                      (e.notes ?? '').toLowerCase().contains(q);
                }).toList();

          final total = filtered.fold<double>(0, (sum, e) => sum + e.amount);

          return RefreshIndicator(
            onRefresh: () => ApiClient.shared.refresh(_load),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total (${filtered.length} expense${filtered.length == 1 ? '' : 's'})',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      ),
                      Icon(Icons.receipt_long, color: colorScheme.primary, size: 32),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search by reason or notes…',
                    prefixIcon: const Icon(Icons.search, size: 20),
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
                            expenses.isEmpty
                                ? 'No expenses yet — add your first one'
                                : 'No expenses match your search',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ExpenseCard(
                        expense: e,
                        busy: _pendingIds.contains(e.id),
                        onEdit: () => _openAdd(existing: e),
                        onDelete: () => _confirmDelete(e),
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
