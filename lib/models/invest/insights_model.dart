/// One recorded change to the plan (amount, ticker or buy day), oldest first.
class SettingsChangeModel {
  const SettingsChangeModel({
    required this.field,
    required this.oldValue,
    required this.newValue,
    required this.changedAt,
  });

  /// MONTHLY_AMOUNT (cents), TICKER or BUY_DAY.
  final String field;
  final String oldValue;
  final String newValue;
  final DateTime changedAt;

  factory SettingsChangeModel.fromJson(Map<String, dynamic> json) =>
      SettingsChangeModel(
        field: json['field'] as String,
        oldValue: json['oldValue'] as String? ?? '',
        newValue: json['newValue'] as String? ?? '',
        changedAt: DateTime.parse(json['changedAt'] as String),
      );
}

/// Model calls on one day.
class AiUsageDay {
  const AiUsageDay({required this.date, required this.calls});

  final DateTime date;
  final int calls;

  factory AiUsageDay.fromJson(Map<String, dynamic> json) => AiUsageDay(
    date: DateTime.parse(json['date'] as String),
    calls: (json['calls'] as num).toInt(),
  );
}

/// Calls per day against the daily cap, oldest day first.
class AiUsageHistoryModel {
  const AiUsageHistoryModel({required this.dailyLimit, required this.days});

  final int dailyLimit;
  final List<AiUsageDay> days;

  factory AiUsageHistoryModel.fromJson(Map<String, dynamic> json) =>
      AiUsageHistoryModel(
        dailyLimit: (json['dailyLimit'] as num).toInt(),
        days: (json['days'] as List)
            .map((e) => AiUsageDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
