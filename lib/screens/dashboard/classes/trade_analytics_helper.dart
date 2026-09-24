import '../../../enums/mistake_tag_enum.dart';
import '../../../enums/session_enum.dart';
import '../../../models/trade_model.dart';

/// Aggregates a bounded, recent slice of trade history into dashboard-ready
/// performance stats (win rate, profit factor, PnL by strategy/session,
/// mistake-tag frequency, streaks).
///
/// Deliberately built from a capped/recent trade fetch (see
/// `TradeService.getRecentForAnalytics`) rather than the full, continuously
/// auto-imported trade history -- same "don't pull everything" discipline
/// the rest of this app's lazy-loading work already follows for the Trades
/// screen.
class TradeAnalyticsHelper {
  final List<Trade> trades;

  TradeAnalyticsHelper(this.trades);

  int? _wins;
  int? _losses;
  int? _breakeven;
  double? _grossProfit;
  double? _grossLoss;
  double? _totalPnl;
  int? _currentStreak;
  List<MapEntry<String, double>>? _pnlByStrategy;
  List<MapEntry<SessionEnum, double>>? _pnlBySession;
  List<MapEntry<MistakeTagEnum, int>>? _mistakeTagFrequency;

  int get totalTrades => trades.length;

  int get wins => _wins ??= trades.where((t) => t.profit > 0).length;

  int get losses => _losses ??= trades.where((t) => t.profit < 0).length;

  int get breakeven => _breakeven ??= trades.where((t) => t.profit == 0).length;

  /// Win rate over decided trades (wins + losses) -- a breakeven trade
  /// shouldn't dilute the rate in either direction.
  double get winRate {
    final decided = wins + losses;
    if (decided == 0) return 0;
    return (wins / decided) * 100;
  }

  double get grossProfit {
    final cached = _grossProfit;
    if (cached != null) return cached;

    final total = trades
        .where((t) => t.profit > 0)
        .fold<double>(0.0, (a, b) => a + b.profit);
    _grossProfit = total;
    return total;
  }

  /// Sum of all losing trades' PnL -- negative (or zero if there are none).
  double get grossLoss {
    final cached = _grossLoss;
    if (cached != null) return cached;

    final total = trades
        .where((t) => t.profit < 0)
        .fold<double>(0.0, (a, b) => a + b.profit);
    _grossLoss = total;
    return total;
  }

  /// Gross profit / |gross loss|. Null (rather than an infinite value) when
  /// there are no losing trades yet in the window.
  double? get profitFactor {
    if (grossLoss == 0) return null;
    return grossProfit / grossLoss.abs();
  }

  double get avgWin => wins == 0 ? 0 : grossProfit / wins;

  /// Average losing trade, kept signed (negative) so it reads naturally
  /// next to Avg Win.
  double get avgLoss => losses == 0 ? 0 : grossLoss / losses;

  double get totalPnl {
    final cached = _totalPnl;
    if (cached != null) return cached;

    final total = trades.fold<double>(0.0, (a, b) => a + b.profit);
    _totalPnl = total;
    return total;
  }

  /// Current streak counted back from the most recent trade: positive N =
  /// N wins in a row, negative N = N losses in a row, 0 if the most recent
  /// trade was breakeven or there's no history yet.
  int get currentStreak {
    final cached = _currentStreak;
    if (cached != null) return cached;
    if (trades.isEmpty) return 0;

    final sorted = List<Trade>.from(trades)
      ..sort((a, b) => b.entryDateTime.compareTo(a.entryDateTime));

    final mostRecent = sorted.first.profit;
    if (mostRecent == 0) return 0;

    final isWinStreak = mostRecent > 0;
    int streak = 0;

    for (final t in sorted) {
      if (isWinStreak && t.profit > 0) {
        streak++;
      } else if (!isWinStreak && t.profit < 0) {
        streak++;
      } else {
        break;
      }
    }

    _currentStreak = isWinStreak ? streak : -streak;
    return _currentStreak!;
  }

  /// Net PnL per strategy, largest-magnitude first. Trades with no
  /// strategy attached are grouped under "No Strategy".
  List<MapEntry<String, double>> pnlByStrategy() {
    final cached = _pnlByStrategy;
    if (cached != null) return cached;

    final Map<String, double> byStrategy = {};

    for (final t in trades) {
      final name = t.strategy?.name ?? 'No Strategy';
      byStrategy.update(name, (v) => v + t.profit, ifAbsent: () => t.profit);
    }

    final entries = byStrategy.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    _pnlByStrategy = entries;
    return entries;
  }

  /// Net PnL per trading session. Trades with no session set are omitted
  /// -- there's nothing meaningful to compare them on.
  List<MapEntry<SessionEnum, double>> pnlBySession() {
    final cached = _pnlBySession;
    if (cached != null) return cached;

    final Map<SessionEnum, double> bySession = {};

    for (final t in trades) {
      final session = t.session;
      if (session == null) continue;
      bySession.update(session, (v) => v + t.profit, ifAbsent: () => t.profit);
    }

    final entries = bySession.entries.toList()
      ..sort((a, b) => a.key.value.compareTo(b.key.value));

    _pnlBySession = entries;
    return entries;
  }

  /// How often each mistake tag shows up across reviewed trades, most
  /// frequent first. Only trades that were reviewed and tagged contribute.
  List<MapEntry<MistakeTagEnum, int>> mistakeTagFrequency() {
    final cached = _mistakeTagFrequency;
    if (cached != null) return cached;

    final Map<MistakeTagEnum, int> counts = {};

    for (final t in trades) {
      final tags = t.mistakeTags;
      if (tags == null) continue;
      for (final tag in tags) {
        counts.update(tag, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _mistakeTagFrequency = entries;
    return entries;
  }
}
