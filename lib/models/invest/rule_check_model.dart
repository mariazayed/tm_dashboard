/// One thing that may not line up with your own rules. A prompt to look,
/// never a verdict; nothing stores it or marks an entry.
class RuleFindingModel {
  const RuleFindingModel({
    required this.check,
    required this.date,
    required this.message,
    this.entryIds = const [],
    this.confidence = 'HIGH',
  });

  /// WAIT_PERIOD, PLAN_CHANGE or MISSED_MONTH.
  final String check;

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

class RuleCheckModel {
  const RuleCheckModel({
    required this.from,
    required this.to,
    required this.waitHours,
    required this.findings,
    required this.checks,
  });

  final String from;
  final String to;
  final int waitHours;
  final List<RuleFindingModel> findings;
  final List<RuleCheckInfoModel> checks;

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
  );
}
