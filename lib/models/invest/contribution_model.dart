class ContributionModel {
  const ContributionModel({
    required this.id,
    required this.contributedOn,
    required this.amountCents,
    required this.shares,
    required this.price,
    required this.feeCents,
    this.notes,
    this.holdingId,
    this.ticker,
  });

  final int id;
  final DateTime contributedOn;
  final int amountCents;
  final double shares;
  final double price;
  final int feeCents;
  final String? notes;

  /// The fund this buy was for; null from a server that predates funds.
  final int? holdingId;
  final String? ticker;

  factory ContributionModel.fromJson(Map<String, dynamic> json) =>
      ContributionModel(
        id: json['id'] as int,
        contributedOn: DateTime.parse(json['contributedOn'] as String),
        amountCents: json['amountCents'] as int,
        shares: (json['shares'] as num).toDouble(),
        price: (json['price'] as num).toDouble(),
        feeCents: json['feeCents'] as int,
        notes: json['notes'] as String?,
        holdingId: json['holdingId'] as int?,
        ticker: json['ticker'] as String?,
      );

  static String dateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
