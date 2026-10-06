enum SourceType {
  book('BOOK', 'Book'),
  video('VIDEO', 'Video'),
  article('ARTICLE', 'Article'),
  podcast('PODCAST', 'Podcast'),
  other('OTHER', 'Other');

  const SourceType(this.api, this.label);

  final String api;
  final String label;

  static SourceType fromApi(String v) => values.firstWhere((t) => t.api == v);
}

enum SourceStatus {
  todo('TO_DO', 'To do'),
  inProgress('IN_PROGRESS', 'In progress'),
  done('DONE', 'Done');

  const SourceStatus(this.api, this.label);

  final String api;
  final String label;

  static SourceStatus fromApi(String v) => values.firstWhere((t) => t.api == v);
}

class LearningSourceModel {
  const LearningSourceModel({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.status,
    this.url,
    this.notes,
  });

  final int id;
  final String title;
  final SourceType sourceType;
  final SourceStatus status;
  final String? url;
  final String? notes;

  factory LearningSourceModel.fromJson(Map<String, dynamic> json) =>
      LearningSourceModel(
        id: json['id'] as int,
        title: json['title'] as String,
        sourceType: SourceType.fromApi(json['sourceType'] as String),
        status: SourceStatus.fromApi(json['status'] as String),
        url: json['url'] as String?,
        notes: json['notes'] as String?,
      );

  /// Body for PUT: the server replaces the whole source, so send every field.
  Map<String, dynamic> toRequest({SourceStatus? status}) => {
    'title': title,
    'sourceType': sourceType.api,
    'url': url,
    'status': (status ?? this.status).api,
    'notes': notes,
  };
}

class LearningNoteModel {
  const LearningNoteModel({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.createdAt,
    this.sourceId,
    this.sourceTitle,
  });

  final int id;
  final String title;
  final String body;
  final int? sourceId;
  final String? sourceTitle;
  final List<String> tags;
  final DateTime createdAt;

  factory LearningNoteModel.fromJson(Map<String, dynamic> json) =>
      LearningNoteModel(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        sourceId: json['sourceId'] as int?,
        sourceTitle: json['sourceTitle'] as String?,
        tags: (json['tags'] as List).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class LearningNotePage {
  const LearningNotePage({
    required this.items,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  final List<LearningNoteModel> items;
  final int page;
  final int total;
  final bool hasMore;

  factory LearningNotePage.fromJson(Map<String, dynamic> json) =>
      LearningNotePage(
        items: (json['items'] as List)
            .map((e) => LearningNoteModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int,
        total: json['total'] as int,
        hasMore: json['hasMore'] as bool,
      );
}

/// How well you remembered a card; the server turns it into the next due date.
enum CardGrade {
  again('AGAIN', 'Again'),
  hard('HARD', 'Hard'),
  good('GOOD', 'Good'),
  easy('EASY', 'Easy');

  const CardGrade(this.api, this.label);

  final String api;
  final String label;
}

class FlashcardModel {
  const FlashcardModel({
    required this.id,
    required this.front,
    required this.back,
    required this.dueOn,
    required this.intervalDays,
    required this.repetitions,
    required this.lapses,
    this.noteId,
  });

  final int id;
  final String front;
  final String back;
  final int? noteId;
  final DateTime dueOn;
  final int intervalDays;
  final int repetitions;
  final int lapses;

  factory FlashcardModel.fromJson(Map<String, dynamic> json) => FlashcardModel(
    id: json['id'] as int,
    front: json['front'] as String,
    back: json['back'] as String,
    noteId: json['noteId'] as int?,
    dueOn: DateTime.parse(json['dueOn'] as String),
    intervalDays: json['intervalDays'] as int,
    repetitions: json['repetitions'] as int,
    lapses: json['lapses'] as int,
  );

  /// "tomorrow", "in 6 days": how soon the card comes back after a review.
  static String nextReviewText(int intervalDays) {
    if (intervalDays <= 1) return 'tomorrow';
    return 'in $intervalDays days';
  }
}

class CardStatsModel {
  const CardStatsModel({
    required this.total,
    required this.due,
    required this.newCards,
    required this.reviewedToday,
  });

  final int total;
  final int due;
  final int newCards;
  final int reviewedToday;

  factory CardStatsModel.fromJson(Map<String, dynamic> json) => CardStatsModel(
    total: json['total'] as int,
    due: json['due'] as int,
    newCards: json['newCards'] as int,
    reviewedToday: json['reviewedToday'] as int,
  );
}
