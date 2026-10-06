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
