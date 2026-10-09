/// One piece of the owner's own writing an answer was based on.
class ChatSource {
  const ChatSource({
    required this.handle,
    required this.type,
    required this.id,
    required this.date,
    required this.snippet,
  });

  /// Short stable name the answer cites it by, such as J12 or N7.
  final String handle;

  /// JOURNAL or NOTE.
  final String type;
  final int id;

  /// yyyy-MM-dd.
  final String date;

  /// The text the assistant was shown (long entries are cut).
  final String snippet;

  bool get isJournal => type == 'JOURNAL';
  DateTime? get when => DateTime.tryParse(date);

  factory ChatSource.fromJson(Map<String, dynamic> json) => ChatSource(
    handle: json['handle'] as String,
    type: json['type'] as String,
    id: (json['id'] as num).toInt(),
    date: json['date'] as String,
    snippet: json['snippet'] as String,
  );
}

/// The server's reply to a question.
class ChatAnswer {
  const ChatAnswer({
    required this.answer,
    required this.sources,
    required this.usedJournal,
    required this.usedNotes,
    required this.truncated,
    required this.cutOff,
    this.model,
    this.refusal,
  });

  final String answer;
  final List<ChatSource> sources;
  final bool usedJournal;
  final bool usedNotes;

  /// Older material was left out of what the assistant read, to fit the size limit.
  final bool truncated;

  /// The assistant hit its reply limit, so the answer may end early.
  final bool cutOff;
  final String? model;

  /// ADVICE when the answer was replaced because it gave advice, EMPTY when
  /// no usable answer came back, otherwise null.
  final String? refusal;

  bool get refused => refusal != null;

  factory ChatAnswer.fromJson(Map<String, dynamic> json) => ChatAnswer(
    answer: json['answer'] as String,
    sources: ((json['sources'] as List?) ?? const [])
        .map((e) => ChatSource.fromJson(e as Map<String, dynamic>))
        .toList(),
    usedJournal: json['usedJournal'] as bool? ?? true,
    usedNotes: json['usedNotes'] as bool? ?? true,
    truncated: json['truncated'] as bool? ?? false,
    cutOff: json['cutOff'] as bool? ?? false,
    model: json['model'] as String?,
    refusal: json['refusal'] as String?,
  );
}

/// One earlier message sent back with a question so a follow-up makes sense.
/// The server keeps no conversation of its own.
class ChatTurn {
  const ChatTurn({required this.assistant, required this.text});

  final bool assistant;
  final String text;

  Map<String, String> toJson() => {
    'role': assistant ? 'assistant' : 'user',
    'text': text,
  };
}

/// Fits the conversation into what the server accepts: at most 6 messages,
/// 2,000 characters each and 6,000 in total. The newest messages win.
class ChatHistory {
  const ChatHistory._();

  static const maxMessages = 6;
  static const maxMessageChars = 2000;
  static const maxTotalChars = 6000;

  static List<ChatTurn> build(List<ChatTurn> turns) {
    final clipped = <ChatTurn>[
      for (final t in turns)
        if (t.text.trim().isNotEmpty)
          ChatTurn(assistant: t.assistant, text: _clip(t.text.trim())),
    ];
    final recent = clipped.length > maxMessages
        ? clipped.sublist(clipped.length - maxMessages)
        : clipped;
    final kept = List<ChatTurn>.of(recent);
    var total = kept.fold<int>(0, (sum, t) => sum + t.text.length);
    while (total > maxTotalChars && kept.isNotEmpty) {
      total -= kept.removeAt(0).text.length;
    }
    return kept;
  }

  static String _clip(String text) {
    if (text.length <= maxMessageChars) return text;
    var cut = maxMessageChars;
    // Do not split a surrogate pair.
    final unit = text.codeUnitAt(cut - 1);
    if (unit >= 0xD800 && unit <= 0xDBFF) cut--;
    return text.substring(0, cut);
  }
}

/// Today's model calls against the server's caps.
class AiUsageModel {
  const AiUsageModel({
    required this.date,
    required this.callsToday,
    required this.dailyLimit,
    required this.perMinuteLimit,
    required this.inputTokens,
    required this.outputTokens,
  });

  final String date;
  final int callsToday;
  final int dailyLimit;
  final int perMinuteLimit;
  final int inputTokens;
  final int outputTokens;

  int get remaining => (dailyLimit - callsToday).clamp(0, dailyLimit);

  factory AiUsageModel.fromJson(Map<String, dynamic> json) => AiUsageModel(
    date: json['date'] as String,
    callsToday: (json['callsToday'] as num).toInt(),
    dailyLimit: (json['dailyLimit'] as num).toInt(),
    perMinuteLimit: (json['perMinuteLimit'] as num).toInt(),
    inputTokens: (json['inputTokens'] as num).toInt(),
    outputTokens: (json['outputTokens'] as num).toInt(),
  );
}
