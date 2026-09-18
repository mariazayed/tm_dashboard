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

  // Price distance that equals 1 pip for this asset -- e.g. 0.0001 for a
  // 4-decimal forex pair, 0.01 for a 2-decimal JPY pair, 0.1 for XAUUSD.
  // Powers the pip figure on manually-entered journal trades (see
  // AddJournalSheet._recalc); left null until set, in which case pips are
  // simply skipped for trades on this asset rather than guessed.
  final double? pipSize;

  Asset({
    required this.id,
    required this.name,
    required this.symbol,
    this.contractSize,
    this.pipSize,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'].toString(),
      name: json['name'],
      symbol: json['symbol'],
      contractSize: json['contractSize'] != null
          ? (json['contractSize'] as num).toDouble()
          : null,
      pipSize: json['pipSize'] != null
          ? (json['pipSize'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'symbol': symbol,
    'contractSize': contractSize,
    'pipSize': pipSize,
  };

  Asset copyWith({
    String? name,
    String? symbol,
    double? contractSize,
    double? pipSize,
  }) {
    return Asset(
      id: id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      contractSize: contractSize ?? this.contractSize,
      pipSize: pipSize ?? this.pipSize,
    );
  }
}
