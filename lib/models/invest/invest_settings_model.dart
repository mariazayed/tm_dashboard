class InvestSettingsModel {
  const InvestSettingsModel({
    required this.monthlyAmountCents,
    required this.currency,
    required this.buyDay,
    required this.ticker,
    required this.startDate,
  });

  final int monthlyAmountCents;
  final String currency;
  final int buyDay;
  final String ticker;
  final DateTime startDate;

  factory InvestSettingsModel.fromJson(Map<String, dynamic> json) =>
      InvestSettingsModel(
        monthlyAmountCents: json['monthlyAmountCents'] as int,
        currency: json['currency'] as String,
        buyDay: json['buyDay'] as int,
        ticker: json['ticker'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
      );
}
