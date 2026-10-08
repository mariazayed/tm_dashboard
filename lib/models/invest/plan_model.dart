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

/// Whether the server could call a language model. The API key itself never reaches the app.
class AiStatusModel {
  const AiStatusModel({required this.configured, this.model, this.reason});

  final bool configured;
  final String? model;

  /// What is missing, when [configured] is false.
  final String? reason;

  factory AiStatusModel.fromJson(Map<String, dynamic> json) => AiStatusModel(
    configured: json['configured'] as bool,
    model: json['model'] as String?,
    reason: json['reason'] as String?,
  );
}

/// The exact text an AI feature would be given, as rendered by the server.
class AiContextPreview {
  const AiContextPreview({
    required this.text,
    required this.characters,
    required this.maxCharacters,
    required this.truncated,
    required this.includeJournal,
    required this.includeNotes,
    this.feature = 'context',
    this.systemPrompt,
    this.snippets = 0,
  });

  final String text;
  final int characters;
  final int maxCharacters;

  /// Older entries were dropped to stay under [maxCharacters].
  final bool truncated;
  final bool includeJournal;
  final bool includeNotes;

  /// "context" for the standing context, or the feature previewed, such as "chat".
  final String feature;

  /// The standing instructions sent along with [text]; null for the plain context.
  final String? systemPrompt;

  /// How many pieces of journal or notes are in [text] (feature previews only).
  final int snippets;

  factory AiContextPreview.fromJson(Map<String, dynamic> json) =>
      AiContextPreview(
        text: json['text'] as String,
        characters: json['characters'] as int,
        maxCharacters: json['maxCharacters'] as int,
        truncated: json['truncated'] as bool,
        includeJournal: json['includeJournal'] as bool,
        includeNotes: json['includeNotes'] as bool,
        feature: json['feature'] as String? ?? 'context',
        systemPrompt: json['systemPrompt'] as String?,
        snippets: (json['snippets'] as num?)?.toInt() ?? 0,
      );
}
