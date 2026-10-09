/// What happened with the optional AI draft of a month's summary.
class SummaryModelInfo {
  const SummaryModelInfo({
    required this.requested,
    required this.ran,
    this.reason,
    this.entriesSent = 0,
    this.entriesSkipped = 0,
  });

  final bool requested;
  final bool ran;

  /// Why there is no draft (AI off, a limit reached, a draft that could not be used, ...).
  final String? reason;
  final int entriesSent;
  final int entriesSkipped;

  factory SummaryModelInfo.fromJson(Map<String, dynamic> json) =>
      SummaryModelInfo(
        requested: json['requested'] as bool? ?? false,
        ran: json['ran'] as bool? ?? false,
        reason: json['reason'] as String?,
        entriesSent: (json['entriesSent'] as num?)?.toInt() ?? 0,
        entriesSkipped: (json['entriesSkipped'] as num?)?.toInt() ?? 0,
      );
}

/// A month's facts and, when it was asked for and could be written, a draft
/// summary of them. The facts are plain arithmetic done by the server; the
/// draft is only worded from them.
class CheckinSummaryModel {
  const CheckinSummaryModel({
    required this.month,
    required this.factsLines,
    required this.state,
    required this.model,
    this.text,
    this.sources = const [],
    this.contributionId,
  });

  /// yyyy-MM.
  final String month;

  /// The facts as plain lines, exactly as the AI would be given them.
  final List<String> factsLines;

  /// DONE, MISSED, PENDING or OVERDUE.
  final String state;

  /// The draft, or null when none was asked for or it could not be written.
  final String? text;

  /// Ids of the journal entries the draft drew on.
  final List<int> sources;

  /// The month's latest buy, to link a check-in entry to it.
  final int? contributionId;
  final SummaryModelInfo model;

  factory CheckinSummaryModel.fromJson(Map<String, dynamic> json) {
    final facts = (json['facts'] as Map?)?.cast<String, dynamic>() ?? const {};
    return CheckinSummaryModel(
      month: json['month'] as String,
      factsLines: ((json['factsLines'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
      state: facts['state'] as String? ?? '',
      text: json['text'] as String?,
      sources: ((json['sources'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
      contributionId: (json['contributionId'] as num?)?.toInt(),
      model: json['model'] == null
          ? const SummaryModelInfo(requested: false, ran: false)
          : SummaryModelInfo.fromJson(json['model'] as Map<String, dynamic>),
    );
  }
}
