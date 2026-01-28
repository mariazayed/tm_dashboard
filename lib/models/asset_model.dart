class Asset {
  final String id;
  final String name;
  final String symbol;

  Asset({
    required this.id,
    required this.name,
    required this.symbol,
  });

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'].toString(),
      name: json['name'],
      symbol: json['symbol'],
    );
  }
}


