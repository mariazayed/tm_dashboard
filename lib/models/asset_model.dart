class Asset {
  final String id;
  final String name;
  final String symbol;

  // Units per 1.0 lot -- e.g. 100000 for a standard forex lot, 1 for a
  // direct share, 100 for a typical options contract. Powers
  // TradeEnrichmentService's risk-in-currency calculations on the backend;
  // left null until set, in which case those calculations are simply
  // skipped for trades on this asset.
  final double? contractSize;

  Asset({
    required this.id,
    required this.name,
    required this.symbol,
    this.contractSize,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'].toString(),
      name: json['name'],
      symbol: json['symbol'],
      contractSize: json['contractSize'] != null
          ? (json['contractSize'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'symbol': symbol,
    'contractSize': contractSize,
  };

  Asset copyWith({
    String? name,
    String? symbol,
    double? contractSize,
  }) {
    return Asset(
      id: id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      contractSize: contractSize ?? this.contractSize,
    );
  }
}
