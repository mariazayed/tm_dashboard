enum JournalEntryType {
  checkin('CHECKIN', 'Check-in'),
  quick('QUICK', 'Quick note'),
  decision('DECISION', 'Decision');

  const JournalEntryType(this.api, this.label);

  /// Name used by the server.
  final String api;
  final String label;

  static JournalEntryType fromApi(String value) =>
      values.firstWhere((t) => t.api == value);
}

class JournalEntryModel {
  const JournalEntryModel({
    required this.id,
    required this.entryType,
    required this.body,
    required this.tags,
    required this.createdAt,
    this.mood,
    this.contributionId,
  });

  final int id;
  final JournalEntryType entryType;

  /// 1 (very worried) to 5 (very calm); optional.
  final int? mood;
  final String body;
  final List<String> tags;
  final int? contributionId;
  final DateTime createdAt;

  factory JournalEntryModel.fromJson(Map<String, dynamic> json) =>
      JournalEntryModel(
        id: json['id'] as int,
        entryType: JournalEntryType.fromApi(json['entryType'] as String),
        mood: json['mood'] as int?,
        body: json['body'] as String,
        tags: (json['tags'] as List).cast<String>(),
        contributionId: json['contributionId'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static const moodLabels = {
    1: 'Very worried',
    2: 'Worried',
    3: 'Neutral',
    4: 'Calm',
    5: 'Very calm',
  };
}

class JournalPage {
  const JournalPage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  final List<JournalEntryModel> items;
  final int page;
  final int total;
  final bool hasMore;

  factory JournalPage.fromJson(Map<String, dynamic> json) => JournalPage(
    items: (json['items'] as List)
        .map((e) => JournalEntryModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: json['page'] as int,
    total: json['total'] as int,
    hasMore: json['hasMore'] as bool,
  );
}

class JournalTagModel {
  const JournalTagModel({required this.name, required this.count});

  final String name;
  final int count;

  factory JournalTagModel.fromJson(Map<String, dynamic> json) =>
      JournalTagModel(
        name: json['name'] as String,
        count: json['count'] as int,
      );
}

class CheckinTemplateModel {
  const CheckinTemplateModel({
    required this.month,
    required this.body,
    this.contributionId,
  });

  /// "YYYY-MM"
  final String month;
  final String body;
  final int? contributionId;

  factory CheckinTemplateModel.fromJson(Map<String, dynamic> json) =>
      CheckinTemplateModel(
        month: json['month'] as String,
        body: json['body'] as String,
        contributionId: json['contributionId'] as int?,
      );
}

/// Mirrors the server's tag rules so suggestions and chips match what is stored:
/// trimmed, no leading '#', single spaces, lower-case. Empty -> null.
String? normalizeTag(String raw) {
  final cleaned = raw
      .trim()
      .replaceFirst(RegExp(r'^#+'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();
  return cleaned.isEmpty ? null : cleaned;
}
