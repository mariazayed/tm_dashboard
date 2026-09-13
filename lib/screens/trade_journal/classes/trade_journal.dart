import 'package:intl/intl.dart';

import '../../../models/trade_model.dart';

/// How trades are bucketed in the combined Trades screen.
///
/// [none] renders every filtered trade as a flat, ungrouped list (this is
/// what used to be the whole of TradeListScreen). The other four bucket
/// trades by [Trade.entryDateTime] -- exitDateTime is never used for
/// grouping, only for display inside a trade's own detail view.
enum TradeGrouping { none, daily, weekly, monthly, custom }

extension TradeGroupingLabel on TradeGrouping {
  String get label {
    switch (this) {
      case TradeGrouping.none:
        return 'None';
      case TradeGrouping.daily:
        return 'Daily';
      case TradeGrouping.weekly:
        return 'Weekly';
      case TradeGrouping.monthly:
        return 'Monthly';
      case TradeGrouping.custom:
        return 'Custom';
    }
  }
}

/// One bucket of trades under a grouping mode (a calendar day/week/month, or
/// a custom N-day interval). Deliberately shaped like the old TradeJournal
/// class it replaces (same stat getters) so TradeGroupCard's rendering logic
/// -- and the summary row's math -- didn't need to change, only what feeds
/// them.
class TradeGroup {
  final String label;

  /// Start of the bucket, used only to sort groups most-recent-first.
  final DateTime sortKey;

  final List<Trade> trades;

  TradeGroup({
    required this.label,
    required this.sortKey,
    required this.trades,
  });

  double get totalProfit => trades.fold(0.0, (sum, t) => sum + t.profit);

  int get tradeCount => trades.length;

  bool get isProfit => totalProfit >= 0;

  int get winCount => trades.where((t) => t.profit > 0).length;

  double get winRate => trades.isEmpty ? 0 : winCount / trades.length * 100;

  bool get hasUnreviewed => trades.any((t) => !t.isReviewed);
}

/// Pure grouping logic, kept separate from the screen's widget tree --
/// mirrors TradeJournalFilters/TradeListFilters' style elsewhere in this app
/// -- so bucketing can be reasoned about (and unit tested) independently of
/// the screen. Called only when the user has picked a grouping mode other
/// than [TradeGrouping.none]; the screen renders the flat trade list itself
/// in that case.
class TradeGrouper {
  static List<TradeGroup> group(
    List<Trade> trades,
    TradeGrouping mode, {
    int customDays = 7,
  }) {
    if (trades.isEmpty || mode == TradeGrouping.none) return [];

    // Custom buckets are anchored to the earliest entryDateTime among the
    // trades being grouped (floored to midnight) so bucket boundaries stay
    // stable as long as the same trades are in view, rather than drifting
    // with "today" every time the screen rebuilds.
    DateTime? customAnchor;
    if (mode == TradeGrouping.custom) {
      final earliest = trades
          .map((t) => t.entryDateTime)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      customAnchor = DateTime(earliest.year, earliest.month, earliest.day);
    }
    final span = customDays < 1 ? 1 : customDays;

    final buckets = <DateTime, List<Trade>>{};
    for (final t in trades) {
      final key = _bucketKey(t.entryDateTime, mode, span, customAnchor);
      buckets.putIfAbsent(key, () => []).add(t);
    }

    final groups = buckets.entries.map((entry) {
      final bucketTrades = entry.value
        ..sort((a, b) => b.entryDateTime.compareTo(a.entryDateTime));
      return TradeGroup(
        label: _label(entry.key, mode, span),
        sortKey: entry.key,
        trades: bucketTrades,
      );
    }).toList();

    groups.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return groups;
  }

  static DateTime _bucketKey(
    DateTime dt,
    TradeGrouping mode,
    int customDays,
    DateTime? customAnchor,
  ) {
    final day = DateTime(dt.year, dt.month, dt.day);

    switch (mode) {
      case TradeGrouping.daily:
        return day;
      case TradeGrouping.weekly:
        // Monday-start week (DateTime.weekday: Monday == 1 .. Sunday == 7).
        return day.subtract(Duration(days: day.weekday - 1));
      case TradeGrouping.monthly:
        return DateTime(dt.year, dt.month, 1);
      case TradeGrouping.custom:
        final anchor = customAnchor!;
        final offsetDays = day.difference(anchor).inDays;
        final index = offsetDays ~/ customDays;
        return anchor.add(Duration(days: index * customDays));
      case TradeGrouping.none:
        return day;
    }
  }

  static String _label(DateTime key, TradeGrouping mode, int customDays) {
    switch (mode) {
      case TradeGrouping.daily:
        return DateFormat('EEEE, dd MMM yyyy').format(key);
      case TradeGrouping.weekly:
        final end = key.add(const Duration(days: 6));
        return '${DateFormat('dd MMM').format(key)} – ${DateFormat('dd MMM yyyy').format(end)}';
      case TradeGrouping.monthly:
        return DateFormat('MMMM yyyy').format(key);
      case TradeGrouping.custom:
        final end = key.add(Duration(days: customDays - 1));
        return '${DateFormat('dd MMM').format(key)} – ${DateFormat('dd MMM yyyy').format(end)}';
      case TradeGrouping.none:
        return DateFormat('dd MMM yyyy').format(key);
    }
  }
}
