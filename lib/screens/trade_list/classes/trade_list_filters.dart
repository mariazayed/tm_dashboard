// SUPERSEDED (unused): TradesScreen (lib/screens/trade_journal/
// trade_journal_screen.dart) uses TradeJournalFilters instead. Left in
// place because this change was made without file-delete access to your
// machine -- safe to delete along with trade_list_screen.dart.
import '../../../enums/trade_direction_enum.dart';
import '../../../models/asset_model.dart';
import '../../../models/strategy_model.dart';
import '../../../models/trade_model.dart';

enum TradeResultFilter { all, win, loss, breakeven }

enum TradeReviewFilter { all, reviewed, unreviewed }

/// Immutable snapshot of every filter control on the Trade List screen, plus
/// the pure function ([apply]) that applies them to a list of trades. Kept
/// as its own class -- mirrors CapitalDashboardHelper's style elsewhere in
/// this app -- so the filtering logic can be reasoned about (and unit
/// tested) independently of the screen's widget tree.
class TradeListFilters {
  final String searchText;
  final Asset? asset;
  final Strategy? strategy;
  final TradeDirectionEnum? direction;
  final TradeResultFilter result;
  final TradeReviewFilter reviewed;

  /// Inclusive lower bound on entryDateTime. Callers should pass midnight
  /// of the chosen day.
  final DateTime? entryFrom;

  /// Inclusive upper bound on entryDateTime. Callers should pass the END
  /// of the chosen day (23:59:59.999), not midnight -- otherwise a trade
  /// entered later that same day would be wrongly excluded.
  final DateTime? entryTo;

  const TradeListFilters({
    this.searchText = '',
    this.asset,
    this.strategy,
    this.direction,
    this.result = TradeResultFilter.all,
    this.reviewed = TradeReviewFilter.all,
    this.entryFrom,
    this.entryTo,
  });

  bool get isActive =>
      searchText.trim().isNotEmpty ||
      asset != null ||
      strategy != null ||
      direction != null ||
      result != TradeResultFilter.all ||
      reviewed != TradeReviewFilter.all ||
      entryFrom != null ||
      entryTo != null;

  TradeListFilters copyWith({
    String? searchText,
    Asset? asset,
    bool clearAsset = false,
    Strategy? strategy,
    bool clearStrategy = false,
    TradeDirectionEnum? direction,
    bool clearDirection = false,
    TradeResultFilter? result,
    TradeReviewFilter? reviewed,
    DateTime? entryFrom,
    bool clearEntryFrom = false,
    DateTime? entryTo,
    bool clearEntryTo = false,
  }) {
    return TradeListFilters(
      searchText: searchText ?? this.searchText,
      asset: clearAsset ? null : (asset ?? this.asset),
      strategy: clearStrategy ? null : (strategy ?? this.strategy),
      direction: clearDirection ? null : (direction ?? this.direction),
      result: result ?? this.result,
      reviewed: reviewed ?? this.reviewed,
      entryFrom: clearEntryFrom ? null : (entryFrom ?? this.entryFrom),
      entryTo: clearEntryTo ? null : (entryTo ?? this.entryTo),
    );
  }

  /// A trade survives only if it matches every active control. Returns the
  /// survivors sorted by entryDateTime, most recent first.
  List<Trade> apply(List<Trade> trades) {
    final query = searchText.trim().toLowerCase();

    final filtered = trades.where((t) {
      if (asset != null && t.asset.id != asset!.id) return false;
      if (strategy != null && t.strategy?.id != strategy!.id) return false;
      if (direction != null && t.direction != direction) return false;

      switch (result) {
        case TradeResultFilter.win:
          if (t.profit <= 0) return false;
          break;
        case TradeResultFilter.loss:
          if (t.profit >= 0) return false;
          break;
        case TradeResultFilter.breakeven:
          if (t.profit != 0) return false;
          break;
        case TradeResultFilter.all:
          break;
      }

      switch (reviewed) {
        case TradeReviewFilter.reviewed:
          if (!t.isReviewed) return false;
          break;
        case TradeReviewFilter.unreviewed:
          if (t.isReviewed) return false;
          break;
        case TradeReviewFilter.all:
          break;
      }

      if (entryFrom != null && t.entryDateTime.isBefore(entryFrom!)) {
        return false;
      }
      if (entryTo != null && t.entryDateTime.isAfter(entryTo!)) {
        return false;
      }

      if (query.isNotEmpty) {
        final haystack = [
          t.asset.symbol,
          t.asset.name,
          t.strategy?.name ?? '',
          t.notes ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) => b.entryDateTime.compareTo(a.entryDateTime));
    return filtered;
  }
}
