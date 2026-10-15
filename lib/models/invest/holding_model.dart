/// What kind of thing a fund is. The names match the server's.
enum AssetClass {
  equity('EQUITY', 'Shares'),
  bonds('BONDS', 'Bonds'),
  cash('CASH', 'Cash'),
  realEstate('REAL_ESTATE', 'Real estate'),
  commodities('COMMODITIES', 'Commodities'),
  other('OTHER', 'Other');

  const AssetClass(this.api, this.label);

  final String api;
  final String label;

  static AssetClass fromApi(String value) =>
      values.firstWhere((c) => c.api == value, orElse: () => AssetClass.other);
}

/// A fund or stock you buy, with the share of the portfolio you aim for.
class HoldingModel {
  const HoldingModel({
    required this.id,
    required this.ticker,
    required this.assetClass,
    required this.region,
    required this.targetPct,
    this.name,
    this.expenseRatio,
    this.notes,
  });

  final int id;
  final String ticker;
  final String? name;
  final AssetClass assetClass;
  final String region;

  /// 0 to 100.
  final double targetPct;

  /// Yearly charge in percent; null when unknown.
  final double? expenseRatio;
  final String? notes;

  /// "VT" or "VT · Total world stock fund".
  String get title =>
      name == null || name!.isEmpty ? ticker : '$ticker · $name';

  factory HoldingModel.fromJson(Map<String, dynamic> json) => HoldingModel(
    id: json['id'] as int,
    ticker: json['ticker'] as String,
    name: json['name'] as String?,
    assetClass: AssetClass.fromApi(json['assetClass'] as String? ?? 'OTHER'),
    region: json['region'] as String? ?? 'Global',
    targetPct: (json['targetPct'] as num).toDouble(),
    expenseRatio: (json['expenseRatio'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
  );

  /// Body for POST and PUT: the server replaces the whole fund.
  Map<String, dynamic> toRequest() => {
    'ticker': ticker,
    'name': name,
    'assetClass': assetClass.api,
    'region': region,
    'targetPct': targetPct,
    'expenseRatio': expenseRatio,
    'notes': notes,
  };

  HoldingModel copyWith({
    String? ticker,
    String? name,
    AssetClass? assetClass,
    String? region,
    double? targetPct,
    double? expenseRatio,
  }) => HoldingModel(
    id: id,
    ticker: ticker ?? this.ticker,
    name: name ?? this.name,
    assetClass: assetClass ?? this.assetClass,
    region: region ?? this.region,
    targetPct: targetPct ?? this.targetPct,
    expenseRatio: expenseRatio ?? this.expenseRatio,
    notes: notes,
  );

  /// Regions offered in the editor; any text is accepted by the server.
  static const regions = [
    'Global',
    'United States',
    'Developed ex-US',
    'Emerging',
    'Europe',
    'Other',
  ];

  /// The targets of [funds] added up, in percent.
  static double targetTotal(Iterable<HoldingModel> funds) =>
      funds.fold(0.0, (a, h) => a + h.targetPct);
}
