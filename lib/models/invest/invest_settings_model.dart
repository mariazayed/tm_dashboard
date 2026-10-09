class InvestSettingsModel {
  const InvestSettingsModel({
    required this.monthlyAmountCents,
    required this.currency,
    required this.buyDay,
    required this.ticker,
    required this.startDate,
    this.timezone = 'UTC',
    this.remindersEnabled = false,
    this.reminderEmail,
    this.reminderFollowupDays = 3,
    this.ruleWaitHours = 72,
  });

  final int monthlyAmountCents;
  final String currency;
  final int buyDay;
  final String ticker;
  final DateTime startDate;
  final String timezone;
  final bool remindersEnabled;
  final String? reminderEmail;
  final int reminderFollowupDays;

  /// Hours your rule asks you to wait before a deviation; 0 turns that check off.
  final int ruleWaitHours;

  factory InvestSettingsModel.fromJson(Map<String, dynamic> json) =>
      InvestSettingsModel(
        monthlyAmountCents: json['monthlyAmountCents'] as int,
        currency: json['currency'] as String,
        buyDay: json['buyDay'] as int,
        ticker: json['ticker'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        timezone: json['timezone'] as String? ?? 'UTC',
        remindersEnabled: json['remindersEnabled'] as bool? ?? false,
        reminderEmail: json['reminderEmail'] as String?,
        reminderFollowupDays: json['reminderFollowupDays'] as int? ?? 3,
        ruleWaitHours: json['ruleWaitHours'] as int? ?? 72,
      );
}
