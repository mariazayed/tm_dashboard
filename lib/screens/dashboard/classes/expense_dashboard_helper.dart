import '../../../models/expense_model.dart';

/// Aggregates the full expense log into dashboard-ready summary stats.
///
/// Unlike [TradeAnalyticsHelper] (deliberately built from a bounded, recent
/// slice of trade history because trades are continuously auto-imported),
/// Expenses is a small, manually-maintained standalone log -- see the
/// original Expenses feature writeup -- so there's no "don't pull
/// everything" concern here. This wraps the same full, paged-under-the-hood
/// fetch already used for the Capital ledger (see
/// ExpenseService.fetchAllPaged / CapitalService.getAllPaged).
class ExpenseDashboardHelper {
  final List<ExpenseModel> expenses;

  ExpenseDashboardHelper(this.expenses);

  double get totalSpent => expenses.fold(0.0, (a, b) => a + b.amount);

  int get totalCount => expenses.length;

  /// Total amount spent per expense reason, largest first. A reason with no
  /// expenses recorded against it simply doesn't appear.
  List<MapEntry<String, double>> totalByReason() {
    final Map<String, double> byReason = {};

    for (final e in expenses) {
      final name = e.expenseReason.name;
      byReason.update(name, (v) => v + e.amount, ifAbsent: () => e.amount);
    }

    final entries = byReason.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries;
  }
}
