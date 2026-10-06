/// One line of the written strategy.
class RuleModel {
  const RuleModel({
    required this.id,
    required this.text,
    required this.position,
  });

  final int id;
  final String text;

  /// 1-based place in the list.
  final int position;

  factory RuleModel.fromJson(Map<String, dynamic> json) => RuleModel(
    id: json['id'] as int,
    text: json['text'] as String,
    position: json['position'] as int,
  );
}

class SentReminder {
  const SentReminder({
    required this.month,
    required this.kind,
    required this.sentAt,
  });

  /// "YYYY-MM"
  final String month;

  /// "DUE" or "FOLLOWUP"
  final String kind;
  final DateTime sentAt;

  factory SentReminder.fromJson(Map<String, dynamic> json) => SentReminder(
    month: json['month'] as String,
    kind: json['kind'] as String,
    sentAt: DateTime.parse(json['sentAt'] as String),
  );

  String get label => kind == 'FOLLOWUP' ? 'follow-up' : 'buy-day reminder';
}

class ReminderStatusModel {
  const ReminderStatusModel({
    required this.emailConfigured,
    required this.recent,
  });

  /// False when the server has no SMTP settings, so no email can go out.
  final bool emailConfigured;
  final List<SentReminder> recent;

  factory ReminderStatusModel.fromJson(Map<String, dynamic> json) =>
      ReminderStatusModel(
        emailConfigured: json['emailConfigured'] as bool,
        recent: (json['recent'] as List)
            .map((e) => SentReminder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Outcome of a test send. A delivery problem is data ([error]), not an exception.
class ReminderTestResult {
  const ReminderTestResult({required this.sent, this.skipped, this.error});

  final bool sent;
  final String? skipped;
  final String? error;

  factory ReminderTestResult.fromJson(Map<String, dynamic> json) =>
      ReminderTestResult(
        sent: json['sent'] as bool,
        skipped: json['skipped'] as String?,
        error: json['error'] as String?,
      );

  /// What to tell the user.
  String get message {
    if (sent) return 'Test email sent. Check your inbox.';
    return error ?? skipped ?? 'Nothing was sent';
  }
}
