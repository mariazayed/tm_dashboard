class SeriesPoint {
  const SeriesPoint({
    required this.date,
    required this.investedCents,
    required this.valueCents,
  });

  final DateTime date;
  final int investedCents;
  final int valueCents;

  factory SeriesPoint.fromJson(Map<String, dynamic> json) => SeriesPoint(
    date: DateTime.parse(json['date'] as String),
    investedCents: json['investedCents'] as int,
    valueCents: json['valueCents'] as int,
  );
}

/// How one fund is doing and where it stands against its target.
class HoldingPerformanceModel {
  const HoldingPerformanceModel({
    required this.holdingId,
    required this.ticker,
    required this.targetPct,
    required this.investedCents,
    required this.valueCents,
    required this.gainCents,
    required this.shares,
    required this.series,
    this.name,
    this.assetClass = 'OTHER',
    this.averageCost,
    this.currentPrice,
    this.gainPercent,
    this.allocationPct,
    this.driftPoints,
  });

  final int holdingId;
  final String ticker;
  final String? name;
  final String assetClass;
  final double targetPct;
  final int investedCents;
  final int valueCents;
  final int gainCents;
  final double shares;
  final double? averageCost;
  final double? currentPrice;
  final double? gainPercent;

  /// Share of the portfolio's value now, in percent; null when nothing is held.
  final double? allocationPct;

  /// Allocation minus target, in percentage points.
  final double? driftPoints;
  final List<SeriesPoint> series;

  factory HoldingPerformanceModel.fromJson(Map<String, dynamic> json) =>
      HoldingPerformanceModel(
        holdingId: json['holdingId'] as int,
        ticker: json['ticker'] as String,
        name: json['name'] as String?,
        assetClass: json['assetClass'] as String? ?? 'OTHER',
        targetPct: (json['targetPct'] as num).toDouble(),
        investedCents: json['investedCents'] as int,
        valueCents: json['valueCents'] as int,
        gainCents: json['gainCents'] as int,
        shares: (json['shares'] as num).toDouble(),
        averageCost: (json['averageCost'] as num?)?.toDouble(),
        currentPrice: (json['currentPrice'] as num?)?.toDouble(),
        gainPercent: (json['gainPercent'] as num?)?.toDouble(),
        allocationPct: (json['allocationPct'] as num?)?.toDouble(),
        driftPoints: (json['driftPoints'] as num?)?.toDouble(),
        series: ((json['series'] as List?) ?? const [])
            .map((e) => SeriesPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PerformanceModel {
  const PerformanceModel({
    required this.ticker,
    required this.currency,
    required this.investedCents,
    required this.feesCents,
    required this.shares,
    required this.valueCents,
    required this.gainCents,
    required this.priceFromCache,
    required this.stale,
    required this.range,
    required this.series,
    this.holdings = const [],
    this.averageCost,
    this.currentPrice,
    this.priceAsOf,
    this.gainPercent,
  });

  final String ticker;
  final String currency;
  final int investedCents;
  final int feesCents;
  final double shares;
  final double? averageCost;
  final double? currentPrice;
  final DateTime? priceAsOf;
  final bool priceFromCache;

  /// The latest price is more than a few days old.
  final bool stale;
  final int valueCents;
  final int gainCents;

  /// Null when nothing has been invested yet.
  final double? gainPercent;
  final String range;
  final List<SeriesPoint> series;

  /// One entry per fund. Empty from a server that predates funds.
  final List<HoldingPerformanceModel> holdings;

  /// More than one fund is held, so per-share figures for the whole portfolio mean nothing.
  bool get isMixed => holdings.length > 1;

  bool get hasContributions => investedCents > 0;

  factory PerformanceModel.fromJson(Map<String, dynamic> json) =>
      PerformanceModel(
        ticker: json['ticker'] as String,
        currency: json['currency'] as String,
        investedCents: json['investedCents'] as int,
        feesCents: json['feesCents'] as int,
        shares: (json['shares'] as num).toDouble(),
        averageCost: (json['averageCost'] as num?)?.toDouble(),
        currentPrice: (json['currentPrice'] as num?)?.toDouble(),
        priceAsOf: json['priceAsOf'] == null
            ? null
            : DateTime.parse(json['priceAsOf'] as String),
        priceFromCache: json['priceFromCache'] as bool,
        stale: json['stale'] as bool,
        valueCents: json['valueCents'] as int,
        gainCents: json['gainCents'] as int,
        gainPercent: (json['gainPercent'] as num?)?.toDouble(),
        range: json['range'] as String,
        series: (json['series'] as List)
            .map((e) => SeriesPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
        holdings: ((json['holdings'] as List?) ?? const [])
            .map(
              (e) =>
                  HoldingPerformanceModel.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );
}

/// Outcome of a manual price refresh. A provider failure arrives as [error]
/// (HTTP 200), with the previously cached prices left untouched.
class PriceRefreshResult {
  const PriceRefreshResult({
    required this.inserted,
    required this.updated,
    this.latestDate,
    this.error,
  });

  final int inserted;
  final int updated;
  final DateTime? latestDate;
  final String? error;

  bool get ok => error == null;

  factory PriceRefreshResult.fromJson(Map<String, dynamic> json) =>
      PriceRefreshResult(
        inserted: json['inserted'] as int,
        updated: json['updated'] as int,
        latestDate: json['latestDate'] == null
            ? null
            : DateTime.parse(json['latestDate'] as String),
        error: json['error'] as String?,
      );
}
