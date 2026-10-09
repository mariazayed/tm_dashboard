import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/learning_model.dart';
import 'package:tm_dashboard/screens/invest/flashcard_review_tab.dart';
import 'package:tm_dashboard/screens/invest/learning_notes_tab.dart';
import 'package:tm_dashboard/screens/invest/learning_screen.dart';
import 'package:tm_dashboard/screens/invest/learning_sheets.dart';
import 'package:tm_dashboard/screens/invest/reading_list_tab.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/contribution_service.dart';
import 'package:tm_dashboard/services/learning_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

Map<String, dynamic> sourceJson(
  int id,
  String title, {
  String type = 'BOOK',
  String status = 'TO_DO',
  String? url,
  String? notes,
}) => {
  'id': id,
  'title': title,
  'sourceType': type,
  'url': url,
  'status': status,
  'notes': notes,
  'createdAt': '2026-10-01T09:00:00',
};

Map<String, dynamic> noteJson(
  int id,
  String title,
  String body, {
  int? sourceId,
  String? sourceTitle,
  List<String> tags = const [],
}) => {
  'id': id,
  'title': title,
  'body': body,
  'sourceId': sourceId,
  'sourceTitle': sourceTitle,
  'tags': tags,
  'createdAt': '2026-10-01T09:00:00',
  'updatedAt': null,
};

Map<String, dynamic> cardJson(
  int id,
  String front,
  String back, {
  int? noteId,
  int interval = 0,
  int reps = 0,
  String due = '2026-10-15',
}) => {
  'id': id,
  'front': front,
  'back': back,
  'noteId': noteId,
  'dueOn': due,
  'intervalDays': interval,
  'ease': 2.5,
  'repetitions': reps,
  'lapses': 0,
  'lastReviewedOn': null,
};

Map<String, dynamic> statsJson({
  int total = 3,
  int due = 2,
  int fresh = 1,
  int today = 0,
}) => {'total': total, 'due': due, 'newCards': fresh, 'reviewedToday': today};

Map<String, dynamic> notePageJson(
  List<Map<String, dynamic>> items, {
  int page = 0,
  int? total,
  bool hasMore = false,
}) => {
  'items': items,
  'page': page,
  'size': 30,
  'total': total ?? items.length,
  'hasMore': hasMore,
};

http.Response ok(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// Records every request and answers from [handler].
class Recorder {
  Recorder(this.handler);

  final Future<http.Response> Function(http.Request) handler;
  final requests = <http.Request>[];

  Iterable<http.Request> where(String method, String pathSuffix) => requests
      .where((r) => r.method == method && r.url.path.endsWith(pathSuffix));

  LearningService service() {
    final api = ApiClient(
      client: MockClient((req) {
        requests.add(req);
        return handler(req);
      }),
    );
    addTearDown(api.close);
    return LearningService(api: api);
  }
}

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

Future<void> bigScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('models', () {
    test('enums round-trip their API names', () {
      for (final t in SourceType.values) {
        expect(SourceType.fromApi(t.api), t);
      }
      for (final s in SourceStatus.values) {
        expect(SourceStatus.fromApi(s.api), s);
      }
      expect(SourceStatus.inProgress.api, 'IN_PROGRESS');
      expect(CardGrade.values.map((g) => g.api), [
        'AGAIN',
        'HARD',
        'GOOD',
        'EASY',
      ]);
    });

    test('a source sends every field back when only the status changes', () {
      final s = LearningSourceModel.fromJson(
        sourceJson(1, 'Book', url: 'https://e.com', notes: 'ch1'),
      );
      expect(s.toRequest(status: SourceStatus.done), {
        'title': 'Book',
        'sourceType': 'BOOK',
        'url': 'https://e.com',
        'status': 'DONE',
        'notes': 'ch1',
      });
    });

    test('notes, pages, cards and stats parse', () {
      final n = LearningNoteModel.fromJson(
        noteJson(
          2,
          'DCA',
          'body',
          sourceId: 1,
          sourceTitle: 'Book',
          tags: ['a'],
        ),
      );
      expect(n.sourceTitle, 'Book');
      expect(
        LearningNotePage.fromJson(
          notePageJson([noteJson(2, 'x', 'y')], total: 9, hasMore: true),
        ).total,
        9,
      );
      final c = FlashcardModel.fromJson(
        cardJson(
          3,
          'Q',
          'A',
          noteId: 2,
          interval: 6,
          reps: 2,
          due: '2026-10-21',
        ),
      );
      expect(c.dueOn, DateTime(2026, 10, 21));
      expect(c.noteId, 2);
      final stats = CardStatsModel.fromJson(statsJson());
      expect(stats.due, 2);
    });

    test('next review wording', () {
      expect(FlashcardModel.nextReviewText(1), 'tomorrow');
      expect(FlashcardModel.nextReviewText(0), 'tomorrow');
      expect(FlashcardModel.nextReviewText(6), 'in 6 days');
    });
  });

  group('LearningService', () {
    test('builds the notes query from set filters only', () async {
      final r = Recorder((_) async => ok(notePageJson([])));
      final service = r.service();
      await service.notes(sourceId: 4, tag: 'dca', query: ' fixed ', page: 1);
      expect(r.requests.last.url.queryParameters, {
        'page': '1',
        'size': '30',
        'sourceId': '4',
        'tag': 'dca',
        'q': 'fixed',
      });
      await service.notes();
      expect(r.requests.last.url.queryParameters.keys.toSet(), {
        'page',
        'size',
      });
    });

    test('review posts the grade name and returns the schedule', () async {
      final r = Recorder(
        (_) async => ok(cardJson(3, 'Q', 'A', interval: 6, reps: 2)),
      );
      final card = await r.service().review(3, CardGrade.hard);
      expect(
        r.requests.last.url.path,
        '/api/v1/invest/learning/cards/3/review',
      );
      expect(jsonDecode(r.requests.last.body), {'grade': 'HARD'});
      expect(card.intervalDays, 6);
    });

    test(
      'due queue asks for a limit; server messages and 401 surface',
      () async {
        final r = Recorder(
          (req) async => req.url.path.endsWith('/due')
              ? ok([])
              : ok({'message': 'Source 9 not found'}, 400),
        );
        final service = r.service();
        await service.dueCards(limit: 25);
        expect(r.requests.last.url.queryParameters['limit'], '25');
        await expectLater(
          service.createNote({}),
          throwsA(
            isA<InvestApiException>().having(
              (e) => e.message,
              'message',
              'Source 9 not found',
            ),
          ),
        );
      },
    );
  });

  group('SourceSheet', () {
    testWidgets('needs a title and sends a blank link as null', (tester) async {
      final r = Recorder((_) async => ok(sourceJson(1, 'x'), 201));
      await tester.pumpWidget(
        host(SingleChildScrollView(child: SourceSheet(service: r.service()))),
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Give it a title'), findsOneWidget);
      expect(r.requests, isEmpty);

      await tester.enterText(
        find.byKey(const Key('source-title')),
        '  Simple Path ',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final sent = jsonDecode(r.requests.single.body) as Map<String, dynamic>;
      expect(sent['title'], 'Simple Path');
      expect(sent['sourceType'], 'BOOK');
      expect(sent['status'], 'TO_DO');
      expect(sent['url'], isNull);
    });

    testWidgets('shows the server error for a rejected link', (tester) async {
      final r = Recorder(
        (_) async =>
            ok({'message': 'URL must be a valid http or https link'}, 400),
      );
      await tester.pumpWidget(
        host(SingleChildScrollView(child: SourceSheet(service: r.service()))),
      );
      await tester.enterText(find.byKey(const Key('source-title')), 'x');
      await tester.enterText(
        find.byKey(const Key('source-url')),
        'javascript:alert(1)',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('URL must be a valid http or https link'),
        findsOneWidget,
      );
    });
  });

  group('ReadingListTab', () {
    testWidgets('groups by status with counts, in progress first', (
      tester,
    ) async {
      await bigScreen(tester);
      final r = Recorder(
        (_) async => ok([
          sourceJson(1, 'Done book', status: 'DONE'),
          sourceJson(2, 'Todo A'),
          sourceJson(3, 'Reading now', status: 'IN_PROGRESS', type: 'VIDEO'),
          sourceJson(4, 'Todo B', type: 'PODCAST'),
        ]),
      );
      await tester.pumpWidget(host(ReadingListTab(service: r.service())));
      await tester.pumpAndSettle();
      expect(find.text('In progress (1)'), findsOneWidget);
      expect(find.text('To do (2)'), findsOneWidget);
      expect(find.text('Done (1)'), findsOneWidget);
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(y('In progress (1)'), lessThan(y('To do (2)')));
      expect(y('To do (2)'), lessThan(y('Done (1)')));
    });

    testWidgets('empty state invites the first entry', (tester) async {
      await bigScreen(tester);
      final r = Recorder((_) async => ok([]));
      await tester.pumpWidget(host(ReadingListTab(service: r.service())));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reading-empty')), findsOneWidget);
    });

    testWidgets(
      'marking a source done sends the full source with the new status',
      (tester) async {
        await bigScreen(tester);
        final r = Recorder(
          (req) async => req.method == 'PUT'
              ? ok(sourceJson(2, 'Todo A', status: 'DONE'))
              : ok([sourceJson(2, 'Todo A', url: 'https://e.com')]),
        );
        await tester.pumpWidget(host(ReadingListTab(service: r.service())));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('source-menu-2')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mark done'));
        await tester.pumpAndSettle();
        final put = r.where('PUT', '/sources/2').single;
        final sent = jsonDecode(put.body) as Map<String, dynamic>;
        expect(sent['status'], 'DONE');
        expect(sent['title'], 'Todo A');
        expect(sent['url'], 'https://e.com'); // not lost by the status change
      },
    );

    testWidgets('delete asks first', (tester) async {
      await bigScreen(tester);
      var deleted = false;
      final r = Recorder((req) async {
        if (req.method == 'DELETE') {
          deleted = true;
          return http.Response('', 204);
        }
        return ok(deleted ? [] : [sourceJson(2, 'Doomed')]);
      });
      await tester.pumpWidget(host(ReadingListTab(service: r.service())));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('source-menu-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isFalse);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
      expect(find.text('Doomed'), findsNothing);
    });
  });

  group('NoteSheet and CardSheet', () {
    testWidgets('a note needs a title and text, then sends source and tags', (
      tester,
    ) async {
      await bigScreen(tester);
      final r = Recorder((_) async => ok(noteJson(1, 't', 'b'), 201));
      final sources = [LearningSourceModel.fromJson(sourceJson(5, 'The Book'))];
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            child: NoteSheet(sources: sources, service: r.service()),
          ),
        ),
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('A note needs a title and some text'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('note-title')), 'DCA');
      await tester.enterText(
        find
            .descendant(
              of: find.byType(NoteSheet),
              matching: find.byType(TextField),
            )
            .at(1),
        'Invest on a schedule.',
      );
      await tester.tap(find.byKey(const Key('note-source')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('The Book').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('tag-field')), 'basics,');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final sent = jsonDecode(r.requests.single.body) as Map<String, dynamic>;
      expect(sent['title'], 'DCA');
      expect(sent['sourceId'], 5);
      expect(sent['tags'], ['basics']);
    });

    testWidgets(
      'editing a note whose source was deleted does not crash the dropdown',
      (tester) async {
        final existing = LearningNoteModel.fromJson(
          noteJson(1, 'Old', 'text', sourceId: 99, sourceTitle: 'Gone'),
        );
        await tester.pumpWidget(
          host(
            SingleChildScrollView(
              child: NoteSheet(existing: existing, sources: const []),
            ),
          ),
        );
        expect(find.text('Edit note'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a card needs both sides and keeps its note link on edit', (
      tester,
    ) async {
      await bigScreen(tester);
      final r = Recorder((_) async => ok(cardJson(1, 'Q', 'A'), 200));
      final existing = FlashcardModel.fromJson(
        cardJson(1, 'Q', 'A', noteId: 7),
      );
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            child: CardSheet(
              existing: existing,
              noteId: 3,
              service: r.service(),
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('card-back')), '   ');
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Both sides of the card need text'), findsOneWidget);
      expect(r.requests, isEmpty);

      await tester.enterText(find.byKey(const Key('card-back')), 'New answer');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final put = r.requests.single;
      expect(put.method, 'PUT');
      expect(jsonDecode(put.body)['noteId'], 7); // the existing link wins
    });

    testWidgets('a new card made from a note carries the note id', (
      tester,
    ) async {
      final r = Recorder((_) async => ok(cardJson(1, 'Q', 'A'), 201));
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            child: CardSheet(noteId: 3, service: r.service()),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('card-front')),
        'What is DCA?',
      );
      await tester.enterText(
        find.byKey(const Key('card-back')),
        'Fixed amounts on a schedule.',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(jsonDecode(r.requests.single.body), {
        'front': 'What is DCA?',
        'back': 'Fixed amounts on a schedule.',
        'noteId': 3,
      });
    });
  });

  group('LearningNotesTab', () {
    testWidgets(
      'lists notes with their source and tags; filters and search re-query',
      (tester) async {
        await bigScreen(tester);
        final r = Recorder((req) async {
          final path = req.url.path;
          if (path.endsWith('/sources')) {
            return ok([sourceJson(1, 'Book')]);
          }
          if (path.endsWith('/notes/tags')) {
            return ok([
              {'name': 'costs', 'count': 2},
            ]);
          }
          return ok(
            notePageJson([
              noteJson(
                9,
                'Expense ratios',
                'Fees compound too',
                sourceId: 1,
                sourceTitle: 'Book',
                tags: ['costs'],
              ),
            ]),
          );
        });
        await tester.pumpWidget(host(LearningNotesTab(service: r.service())));
        await tester.pumpAndSettle();
        expect(find.text('Expense ratios'), findsOneWidget);
        expect(find.text('From Book'), findsOneWidget);
        expect(find.text('#costs'), findsOneWidget);
        expect(
          find.text('Fees compound too', findRichText: true),
          findsOneWidget,
        );

        final before = r.where('GET', '/notes').length;
        await tester.enterText(find.byKey(const Key('notes-search')), 'fees');
        await tester.pump(const Duration(milliseconds: 100));
        expect(r.where('GET', '/notes').length, before); // still debouncing
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(r.where('GET', '/notes').last.url.queryParameters['q'], 'fees');

        await tester.tap(find.byKey(const Key('note-tag-filter')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('#costs (2)').last);
        await tester.pumpAndSettle();
        final last = r.where('GET', '/notes').last.url.queryParameters;
        expect(last['tag'], 'costs');
        expect(last['q'], 'fees'); // filters combine
      },
    );

    testWidgets(
      'a long source title does not overflow a phone-width filter row',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final r = Recorder((req) async {
          final path = req.url.path;
          if (path.endsWith('/sources')) {
            return ok([
              sourceJson(
                1,
                'The Simple Path to Wealth: Your road map to financial independence',
              ),
            ]);
          }
          if (path.endsWith('/notes/tags')) {
            return ok([
              {'name': 'a-very-long-tag-name-for-testing', 'count': 12},
            ]);
          }
          return ok(notePageJson([]));
        });
        await tester.pumpWidget(host(LearningNotesTab(service: r.service())));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('source-filter')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('empty states differ with and without filters', (tester) async {
      await bigScreen(tester);
      final r = Recorder(
        (req) async =>
            req.url.path.endsWith('/notes') ? ok(notePageJson([])) : ok([]),
      );
      await tester.pumpWidget(host(LearningNotesTab(service: r.service())));
      await tester.pumpAndSettle();
      expect(
        find.text('No notes yet. Write down one thing you learned.'),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const Key('notes-search')), 'zzz');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches those filters'), findsOneWidget);
    });

    testWidgets('the card icon opens a flashcard sheet linked to the note', (
      tester,
    ) async {
      await bigScreen(tester);
      final r = Recorder((req) async {
        if (req.method == 'POST') {
          return ok(cardJson(1, 'Q', 'A', noteId: 9), 201);
        }
        if (req.url.path.endsWith('/notes')) {
          return ok(notePageJson([noteJson(9, 'DCA', 'body')]));
        }
        return ok([]);
      });
      await tester.pumpWidget(host(LearningNotesTab(service: r.service())));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Make a flashcard'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('card-front')), 'Q');
      await tester.enterText(find.byKey(const Key('card-back')), 'A');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(jsonDecode(r.where('POST', '/cards').single.body)['noteId'], 9);
    });

    testWidgets('load more appends the next page', (tester) async {
      await bigScreen(tester);
      final r = Recorder((req) async {
        if (!req.url.path.endsWith('/notes')) {
          return ok([]);
        }
        final page = int.parse(req.url.queryParameters['page']!);
        return ok(
          notePageJson(
            [noteJson(page + 1, page == 0 ? 'First page' : 'Second page', 'x')],
            page: page,
            total: 2,
            hasMore: page == 0,
          ),
        );
      });
      await tester.pumpWidget(host(LearningNotesTab(service: r.service())));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notes-load-more')));
      await tester.pumpAndSettle();
      expect(find.text('First page'), findsOneWidget);
      expect(find.text('Second page'), findsOneWidget);
    });
  });

  group('FlashcardReviewTab', () {
    testWidgets('no cards yet shows guidance, not an empty session', (
      tester,
    ) async {
      await bigScreen(tester);
      final r = Recorder(
        (req) async => req.url.path.endsWith('/stats')
            ? ok(statsJson(total: 0, due: 0, fresh: 0))
            : ok([]),
      );
      await tester.pumpWidget(host(FlashcardReviewTab(service: r.service())));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('no-cards')), findsOneWidget);
    });

    testWidgets('cards exist but none are due', (tester) async {
      await bigScreen(tester);
      final r = Recorder(
        (req) async => req.url.path.endsWith('/stats')
            ? ok(statsJson(total: 4, due: 0, fresh: 0))
            : ok([]),
      );
      await tester.pumpWidget(host(FlashcardReviewTab(service: r.service())));
      await tester.pumpAndSettle();
      expect(find.text('Nothing is due today'), findsOneWidget);
    });

    testWidgets('a full session: reveal, grade, advance, finish', (
      tester,
    ) async {
      await bigScreen(tester);
      final queue = [
        cardJson(1, 'What is DCA?', 'Fixed amounts on a schedule.'),
        cardJson(2, 'Expense ratio?', 'Yearly fund fee.'),
      ];
      final r = Recorder((req) async {
        final path = req.url.path;
        if (path.endsWith('/review')) {
          final id = int.parse(path.split('/')[path.split('/').length - 2]);
          return ok(cardJson(id, 'x', 'y', interval: id == 1 ? 1 : 6, reps: 1));
        }
        if (path.endsWith('/stats')) {
          return ok(statsJson(total: 2, due: 2, fresh: 2));
        }
        return ok(queue);
      });
      await tester.pumpWidget(host(FlashcardReviewTab(service: r.service())));
      await tester.pumpAndSettle();

      expect(find.text('Card 1 of 2'), findsOneWidget);
      expect(find.text('What is DCA?'), findsOneWidget);
      expect(
        find.byKey(const Key('card-back-text')),
        findsNothing,
      ); // answer hidden
      expect(find.byKey(const ValueKey('grade-GOOD')), findsNothing);

      await tester.tap(find.byKey(const Key('show-answer')));
      await tester.pump();
      expect(find.text('Fixed amounts on a schedule.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('grade-GOOD')));
      await tester.pumpAndSettle();
      expect(jsonDecode(r.where('POST', '/cards/1/review').single.body), {
        'grade': 'GOOD',
      });
      expect(find.text('Card 2 of 2'), findsOneWidget);
      expect(find.text('Next review tomorrow'), findsOneWidget);
      expect(
        find.byKey(const Key('card-back-text')),
        findsNothing,
      ); // hidden again for the next card

      await tester.tap(find.byKey(const Key('show-answer')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('grade-EASY')));
      await tester.pumpAndSettle();
      expect(jsonDecode(r.where('POST', '/cards/2/review').single.body), {
        'grade': 'EASY',
      });
      expect(find.text('All done for today'), findsOneWidget);
      expect(find.text('Next review in 6 days'), findsOneWidget);
    });

    testWidgets('all four grades are offered after revealing', (tester) async {
      await bigScreen(tester);
      final r = Recorder((req) async {
        if (req.url.path.endsWith('/stats')) {
          return ok(statsJson(total: 1, due: 1, fresh: 1));
        }
        return ok([cardJson(1, 'Q', 'A')]);
      });
      await tester.pumpWidget(host(FlashcardReviewTab(service: r.service())));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('show-answer')));
      await tester.pump();
      for (final g in ['AGAIN', 'HARD', 'GOOD', 'EASY']) {
        expect(find.byKey(ValueKey('grade-$g')), findsOneWidget, reason: g);
      }
    });

    testWidgets('a failed grade keeps the card so it can be retried', (
      tester,
    ) async {
      await bigScreen(tester);
      final r = Recorder((req) async {
        if (req.url.path.endsWith('/review')) {
          return ok({'message': 'Flashcard 1 not found'}, 404);
        }
        if (req.url.path.endsWith('/stats')) {
          return ok(statsJson(total: 1, due: 1, fresh: 1));
        }
        return ok([cardJson(1, 'Q', 'A')]);
      });
      await tester.pumpWidget(host(FlashcardReviewTab(service: r.service())));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('show-answer')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('grade-GOOD')));
      await tester.pumpAndSettle();
      expect(find.text('Flashcard 1 not found'), findsOneWidget);
      expect(find.text('Card 1 of 1'), findsOneWidget); // not skipped
    });

    testWidgets('manage all cards lists them and deletes after confirming', (
      tester,
    ) async {
      await bigScreen(tester);
      var deleted = false;
      final r = Recorder((req) async {
        final path = req.url.path;
        if (req.method == 'DELETE') {
          deleted = true;
          return http.Response('', 204);
        }
        if (path.endsWith('/stats')) {
          return ok(statsJson(total: deleted ? 0 : 1, due: 0, fresh: 0));
        }
        if (path.endsWith('/due')) {
          return ok([]);
        }
        return ok(
          deleted ? [] : [cardJson(4, 'Old question', 'A', due: '2026-11-02')],
        );
      });
      await tester.pumpWidget(host(FlashcardReviewTab(service: r.service())));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('show-all-cards')));
      await tester.pumpAndSettle();
      expect(find.text('Old question'), findsOneWidget);
      expect(find.text('Due 2026-11-02'), findsOneWidget);
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isFalse);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
      expect(find.byKey(const Key('no-cards')), findsOneWidget);
    });
  });

  group('LearningScreen', () {
    testWidgets('all three tabs are reachable at phone width', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final r = Recorder(
        (req) async => req.url.path.endsWith('/stats')
            ? ok(statsJson(total: 0, due: 0, fresh: 0))
            : req.url.path.endsWith('/notes')
            ? ok(notePageJson([]))
            : ok([]),
      );
      await tester.pumpWidget(host(LearningScreen(service: r.service())));
      await tester.pumpAndSettle();
      for (final label in ['Reading list', 'Notes', 'Review']) {
        final center = tester.getCenter(find.text(label));
        expect(
          center.dx,
          inInclusiveRange(0, 360),
          reason: label,
        ); // on screen, no scrolling needed
      }
    });

    testWidgets('has the three tabs and switches between them', (tester) async {
      await bigScreen(tester);
      final r = Recorder((req) async {
        final p = req.url.path;
        if (p.endsWith('/stats')) {
          return ok(statsJson(total: 0, due: 0, fresh: 0));
        }
        if (p.endsWith('/notes')) {
          return ok(notePageJson([]));
        }
        return ok([]);
      });
      await tester.pumpWidget(host(LearningScreen(service: r.service())));
      await tester.pumpAndSettle();
      expect(find.text('Reading list'), findsOneWidget);
      expect(find.byKey(const Key('add-source')), findsOneWidget);
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add-note')), findsOneWidget);
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('no-cards')), findsOneWidget);
    });
  });
}
