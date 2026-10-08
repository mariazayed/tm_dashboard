/// One tag the AI proposed for an entry draft. Only a suggestion: nothing is
/// created until the owner keeps it and saves the entry.
class TagSuggestionModel {
  const TagSuggestionModel({
    required this.tag,
    required this.isNew,
    this.reason = '',
  });

  final String tag;

  /// True when the owner has no such tag yet.
  final bool isNew;
  final String reason;

  factory TagSuggestionModel.fromJson(Map<String, dynamic> json) =>
      TagSuggestionModel(
        tag: json['tag'] as String,
        isNew: json['isNew'] as bool? ?? false,
        reason: json['reason'] as String? ?? '',
      );
}
