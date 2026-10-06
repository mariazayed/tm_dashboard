enum MonthState { done, missed, pending, overdue }

class MonthStatus {
  const MonthStatus({
    required this.month,
    required this.state,
    required this.contributions,
    required this.totalCents,
  });

  /// "YYYY-MM"
  final String month;
  final MonthState state;
  final int contributions;
  final int totalCents;

  factory MonthStatus.fromJson(Map<String, dynamic> json) => MonthStatus(
    month: json['month'] as String,
    state: MonthState.values.byName((json['state'] as String).toLowerCase()),
    contributions: json['contributions'] as int,
    totalCents: json['totalCents'] as int,
  );
}

class ContributionStatusModel {
  const ContributionStatusModel({
    required this.months,
    required this.currentStreak,
    required this.longestStreak,
    required this.missedCount,
    this.currentDueDate,
    this.daysUntilDue,
  });

  final List<MonthStatus> months;
  final int currentStreak;
  final int longestStreak;
  final int missedCount;
  final DateTime? currentDueDate;
  final int? daysUntilDue;

  /// The current (last) month, or null before the plan starts.
  MonthStatus? get current => months.isEmpty ? null : months.last;

  factory ContributionStatusModel.fromJson(Map<String, dynamic> json) =>
      ContributionStatusModel(
        months: (json['months'] as List)
            .map((m) => MonthStatus.fromJson(m as Map<String, dynamic>))
            .toList(),
        currentStreak: json['currentStreak'] as int,
        longestStreak: json['longestStreak'] as int,
        missedCount: json['missedCount'] as int,
        currentDueDate: json['currentDueDate'] == null
            ? null
            : DateTime.parse(json['currentDueDate'] as String),
        daysUntilDue: json['daysUntilDue'] as int?,
      );
}

class CsvImportResult {
  const CsvImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
  });

  final int imported;
  final int skipped;
  final List<String> errors;

  bool get ok => errors.isEmpty;

  factory CsvImportResult.fromJson(Map<String, dynamic> json) =>
      CsvImportResult(
        imported: json['imported'] as int,
        skipped: json['skipped'] as int,
        errors: (json['errors'] as List)
            .map((e) => 'Line ${e['line']}: ${e['message']}')
            .toList(),
      );
}
