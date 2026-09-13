import '../../../enums/trade_direction_enum.dart';
import '../../../models/asset_model.dart';
import '../../../models/strategy_model.dart';
import '../../../models/trade_model.dart';

enum JournalResultFilter { all, win, loss, breakeven }

enum JournalReviewFilter { all, reviewed, unreviewed }

/// Immutable filter-state for the Trade Journal screen -- mirrors
/// TradeListFilters' shape (lib/screens/trade_list/classes/trade_list_filters.dart)
/// so both screens feel consistent, but [apply] runs over the *flat* trade
/// list before it gets grouped into journals: a journal window survives
/// with only the trades inside it that match every active control, and a
/// window whose trades are all filtered out simply disappears.
class TradeJournalFilters {
  final String searchText;
  final Asset? asset;
  final Strategy? strategy;
  final TradeDirectionEnum? direction;
  final JournalResultFilter result;
  final JournalReviewFilter reviewed;

  /// Inclusive lower bound on entryDateTime. Callers should pass midnight
  /// of the chosen day.
  final DateTime? entryFrom;

  /// Inclusive upper bound on entryDateTime. Callers should pass the END
  /// of the chosen day (23:59:59.999), not midnight -- otherwise a trade
  /// entered later that same day would be wrongly excluded.
  final DateTime? entryTo;

  const TradeJournalFilters({
    this.searchText = '',
    this.asset,
    this.strategy,
    this.direction,
    this.result = JournalResultFilter.all,
    this.reviewed = JournalReviewFilter.all,
    this.entryFrom,
    this.entryTo,
  });

  bool get isActive =>
      searchText.trim().isNotEmpty ||
      asset != null ||
      strategy != null ||
      direction != null ||
      result != JournalResultFilter.all ||
      reviewed != JournalReviewFilter.all ||
      entryFrom != null ||
      entryTo != null;

  TradeJournalFilters copyWith({
    String? searchText,
    Asset? asset,
    bool clearAsset = false,
    Strategy? strategy,
    bool clearStrategy = false,
    TradeDirectionEnum? direction,
    bool clearDirection = false,
    JournalResultFilter? result,
    JournalReviewFilter? reviewed,
    DateTime? entryFrom,
    bool clearEntryFrom = false,
    DateTime? entryTo,
    bool clearEntryTo = false,
  }) {
    return TradeJournalFilters(
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

  /// Trades surviving every active control, sorted most-recent entry first.
  /// (Grouping into journals happens afterwards on the caller's side; the
  /// sort here just keeps a lone filtered list sensible too.)
  List<Trade> apply(List<Trade> trades) {
    final query = searchText.trim().toLowerCase();

    final filtered = trades.where((t) {
      if (asset != null && t.asset.id != asset!.id) return false;
      if (strategy != null && t.strategy?.id != strategy!.id) return false;
      if (direction != null && t.direction != direction) return false;

      switch (result) {
        case JournalResultFilter.win:
          if (t.profit <= 0) return false;
          break;
        case JournalResultFilter.loss:
          if (t.profit >= 0) return false;
          break;
        case JournalResultFilter.breakeven:
          if (t.profit != 0) return false;
          break;
        case JournalResultFilter.all:
          break;
      }

      switch (reviewed) {
        case JournalReviewFilter.reviewed:
          if (!t.isReviewed) return false;
          break;
        case JournalReviewFilter.unreviewed:
          if (t.isReviewed) return false;
          break;
        case JournalReviewFilter.all:
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
