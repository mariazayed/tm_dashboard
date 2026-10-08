/// One thing that may not line up with your own rules. A prompt to look,
/// never a verdict; nothing stores it or marks an entry.
class RuleFindingModel {
  const RuleFindingModel({
    required this.check,
    required this.date,
    required this.message,
    this.entryIds = const [],
    this.confidence = 'HIGH',
    this.source = 'DETERMINISTIC',
    this.ruleId,
    this.quote,
  });

  /// WAIT_PERIOD, PLAN_CHANGE or MISSED_MONTH (exact), or MODEL_REVIEW.
  final String check;

  /// DETERMINISTIC (plain code on the server) or MODEL (the AI's reading).
  final String source;

  /// The rule it relates to (AI findings only).
  final int? ruleId;

  /// Your own words, checked to be really in the entry (AI findings only).
  final String? quote;

  bool get isModel => source == 'MODEL';

  /// yyyy-MM-dd.
  final String date;
  final String message;
  final List<int> entryIds;
  final String confidence;

  factory RuleFindingModel.fromJson(Map<String, dynamic> json) =>
      RuleFindingModel(
        check: json['check'] as String,
        date: json['date'] as String,
        message: json['message'] as String,
        entryIds: ((json['entryIds'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        confidence: json['confidence'] as String? ?? 'HIGH',
        source: json['source'] as String? ?? 'DETERMINISTIC',
        ruleId: (json['ruleId'] as num?)?.toInt(),
        quote: json['quote'] as String?,
      );
}

/// Whether a check ran, or why it is off.
class RuleCheckInfoModel {
  const RuleCheckInfoModel({
    required this.code,
    required this.label,
    required this.status,
    this.note,
  });

  final String code;
  final String label;

  /// RAN or OFF.
  final String status;
  final String? note;

  bool get isOff => status == 'OFF';

  factory RuleCheckInfoModel.fromJson(Map<String, dynamic> json) =>
      RuleCheckInfoModel(
        code: json['code'] as String,
        label: json['label'] as String,
        status: json['status'] as String,
        note: json['note'] as String?,
      );
}

/// What happened with the optional AI reading of the journal.
class RuleCheckModelInfo {
  const RuleCheckModelInfo({
    required this.requested,
    required this.ran,
    this.reason,
    this.entriesChecked = 0,
    this.entriesSkipped = 0,
    this.dropped = 0,
  });

  final bool requested;
  final bool ran;

  /// Why it did not run (AI off, a limit reached, nothing to read, ...).
  final String? reason;
  final int entriesChecked;

  /// Entries in the range the AI did not read (only the newest are sent).
  final int entriesSkipped;

  /// Suggestions discarded because they named a rule, entry or text that was
  /// not really there, or gave advice.
  final int dropped;

  factory RuleCheckModelInfo.fromJson(Map<String, dynamic> json) =>
      RuleCheckModelInfo(
        requested: json['requested'] as bool? ?? false,
        ran: json['ran'] as bool? ?? false,
        reason: json['reason'] as String?,
        entriesChecked: (json['entriesChecked'] as num?)?.toInt() ?? 0,
        entriesSkipped: (json['entriesSkipped'] as num?)?.toInt() ?? 0,
        dropped: (json['dropped'] as num?)?.toInt() ?? 0,
      );
}

class RuleCheckModel {
  const RuleCheckModel({
    required this.from,
    required this.to,
    required this.waitHours,
    required this.findings,
    required this.checks,
    this.model,
  });

  final String from;
  final String to;
  final int waitHours;
  final List<RuleFindingModel> findings;
  final List<RuleCheckInfoModel> checks;

  /// Null from a server that predates the AI reading.
  final RuleCheckModelInfo? model;

  factory RuleCheckModel.fromJson(Map<String, dynamic> json) => RuleCheckModel(
    from: json['from'] as String,
    to: json['to'] as String,
    waitHours: (json['waitHours'] as num).toInt(),
    findings: ((json['findings'] as List?) ?? const [])
        .map((e) => RuleFindingModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    checks: ((json['checks'] as List?) ?? const [])
        .map((e) => RuleCheckInfoModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    model: json['model'] == null
        ? null
        : RuleCheckModelInfo.fromJson(json['model'] as Map<String, dynamic>),
  );
}
