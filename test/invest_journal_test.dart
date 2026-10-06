import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/journal_model.dart';
import 'package:tm_dashboard/screens/invest/journal_entry_sheet.dart';
import 'package:tm_dashboard/screens/invest/journal_screen.dart';
import 'package:tm_dashboard/screens/invest/tag_input.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/contribution_service.dart';
import 'package:tm_dashboard/services/journal_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';
import 'package:tm_dashboard/widgets/md_editor_field.dart';

Map<String, dynamic> entryJson(
  int id,
  String body, {
  String type = 'QUICK',
  int? mood,
  List<String> tags = const [],
  int? contributionId,
}) => {
  'id': id,
  'entryType': type,
  'mood': mood,
  'body': body,
  'tags': tags,
  'contributionId': contributionId,
  'createdAt': '2026-10-06T09:30:00',
  'updatedAt': null,
};

Map<String, dynamic> pageJson(
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

JournalService serviceWith(
  Future<http.Response> Function(http.Request) handler,
) {
  final api = ApiClient(client: MockClient(handler));
  addTearDown(api.close);
  return JournalService(api: api);
}

http.Response ok(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  group('normalizeTag', () {
    test('matches the server rules', () {
      expect(normalizeTag('  #Emotion '), 'emotion');
      expect(normalizeTag('##Market   Event'), 'market event');
      expect(normalizeTag('#'), isNull);
      expect(normalizeTag('   '), isNull);
    });
  });

  group('models', () {
    test('entry, page, tag and template parse', () {
      final e = JournalEntryModel.fromJson(
        entryJson(
          1,
          'hi',
          type: 'CHECKIN',
          mood: 4,
          tags: ['a'],
          contributionId: 9,
        ),
      );
      expect(e.entryType, JournalEntryType.checkin);
      expect(e.mood, 4);
      expect(e.contributionId, 9);
      expect(e.createdAt, DateTime(2026, 10, 6, 9, 30));

      final page = JournalPage.fromJson(
        pageJson([entryJson(1, 'x')], total: 40, hasMore: true),
      );
      expect(page.total, 40);
      expect(page.hasMore, isTrue);

      expect(JournalTagModel.fromJson({'name': 'x', 'count': 2}).count, 2);
      final t = CheckinTemplateModel.fromJson({
        'month': '2026-10',
        'body': '## Hi',
        'contributionId': null,
      });
      expect(t.contributionId, isNull);
    });

    test('entry types map to and from the API names', () {
      for (final t in JournalEntryType.values) {
        expect(JournalEntryType.fromApi(t.api), t);
      }
    });
  });

  group('JournalService', () {
    test('list sends only the filters that are set', () async {
      late Uri seen;
      final service = serviceWith((req) async {
        seen = req.url;
        return ok(pageJson([]));
      });
      await service.list(
        tag: 'emotion',
        type: JournalEntryType.decision,
        query: '  loud  ',
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 31),
        page: 2,
      );
      expect(seen.path, '/api/v1/invest/journal');
      expect(seen.queryParameters, {
        'page': '2',
        'size': '30',
        'tag': 'emotion',
        'type': 'DECISION',
        'q': 'loud',
        'from': '2026-10-01',
        'to': '2026-10-31',
      });

      await service.list(query: '   ');
      expect(seen.queryParameters.keys.toSet(), {'page', 'size'});
    });

    test('create and update send the payload and parse the reply', () async {
      final seen = <http.Request>[];
      final service = serviceWith((req) async {
        seen.add(req);
        return ok(entryJson(7, 'hello'), req.method == 'POST' ? 201 : 200);
      });
      final created = await service.create({'body': 'hello'});
      final updated = await service.update(7, {'body': 'hello'});
      expect(created.id, 7);
      expect(updated.id, 7);
      expect(seen.map((r) => r.method), ['POST', 'PUT']);
      expect(seen[1].url.path, '/api/v1/invest/journal/7');
      expect(jsonDecode(seen[0].body), {'body': 'hello'});
    });

    test('errors carry the server message; 401 is flagged', () async {
      final bad = serviceWith(
        (_) async => ok({'message': 'Contribution 9 not found'}, 400),
      );
      await expectLater(
        bad.create({}),
        throwsA(
          isA<InvestApiException>().having(
            (e) => e.message,
            'message',
            'Contribution 9 not found',
          ),
        ),
      );
      final unauth = serviceWith((_) async => http.Response('', 401));
      await expectLater(
        unauth.tags(),
        throwsA(
          isA<InvestApiException>().having(
            (e) => e.unauthorized,
            'unauthorized',
            isTrue,
          ),
        ),
      );
    });

    test('delete accepts 204', () async {
      final service = serviceWith((_) async => http.Response('', 204));
      await service.delete(3);
    });
  });

  group('TagInput', () {
    Future<List<String>> pumpInput(
      WidgetTester tester, {
      List<String> initial = const [],
      List<String> suggestions = const ['emotion', 'learning', 'market-event'],
      int max = 10,
    }) async {
      final current = [...initial];
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => TagInput(
              tags: current,
              suggestions: suggestions,
              maxTags: max,
              onChanged: (t) => setState(() {
                current
                  ..clear()
                  ..addAll(t);
              }),
            ),
          ),
        ),
      );
      return current;
    }

    testWidgets('Enter adds a normalised tag; duplicates are ignored', (
      tester,
    ) async {
      final tags = await pumpInput(tester);
      await tester.enterText(
        find.byKey(const Key('tag-field')),
        '  #Big Drop ',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.enterText(find.byKey(const Key('tag-field')), 'BIG drop');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(tags, ['big drop']);
      expect(find.text('#big drop'), findsOneWidget);
    });

    testWidgets('a comma commits the tag', (tester) async {
      final tags = await pumpInput(tester);
      await tester.enterText(find.byKey(const Key('tag-field')), 'learning,');
      await tester.pump();
      expect(tags, ['learning']);
    });

    testWidgets('suggests existing tags and skips ones already chosen', (
      tester,
    ) async {
      await pumpInput(tester, initial: ['emotion']);
      await tester.enterText(find.byKey(const Key('tag-field')), 'e');
      await tester.pumpAndSettle();
      expect(find.text('#market-event'), findsOneWidget);
      expect(find.text('#learning'), findsOneWidget);
      expect(
        find.text('#emotion'),
        findsOneWidget,
      ); // the chip only, not offered again
    });

    testWidgets('several comma-separated tags are added at once', (
      tester,
    ) async {
      final tags = await pumpInput(tester);
      await tester.enterText(
        find.byKey(const Key('tag-field')),
        'one, Two ,#three',
      );
      await tester.pump();
      expect(tags, ['one', 'two', 'three']);
    });

    testWidgets('tapping a suggestion adds it', (tester) async {
      final tags = await pumpInput(tester);
      await tester.enterText(find.byKey(const Key('tag-field')), 'mark');
      await tester.pumpAndSettle();
      await tester.tap(find.text('#market-event').last);
      await tester.pumpAndSettle();
      expect(tags, ['market-event']);
    });

    testWidgets('deleting a chip removes the tag', (tester) async {
      final tags = await pumpInput(tester, initial: ['a', 'b']);
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('tag-a')),
          matching: find.byType(Icon),
        ),
      );
      await tester.pump();
      expect(tags, ['b']);
    });

    testWidgets('stops at the tag limit', (tester) async {
      final tags = await pumpInput(tester, initial: ['a', 'b'], max: 2);
      expect(find.text('Tag limit reached'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byKey(const Key('tag-field'))).enabled,
        isFalse,
      );
      expect(tags, hasLength(2));
    });
  });

  group('JournalEntrySheet', () {
    Finder bodyField() => find.descendant(
      of: find.byType(MdEditorField),
      matching: find.byType(TextField),
    );

    testWidgets('refuses an empty note without calling the server', (
      tester,
    ) async {
      var calls = 0;
      final service = serviceWith((_) async {
        calls++;
        return ok(entryJson(1, 'x'));
      });
      await tester.pumpWidget(
        host(SingleChildScrollView(child: JournalEntrySheet(service: service))),
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.text('Write something first'), findsOneWidget);
      expect(calls, 0);
    });

    testWidgets('quick capture sends type, mood, body and tags', (
      tester,
    ) async {
      late Map<String, dynamic> sent;
      final service = serviceWith((req) async {
        sent = jsonDecode(req.body);
        return ok(entryJson(1, 'x'), 201);
      });
      await tester.pumpWidget(
        host(SingleChildScrollView(child: JournalEntrySheet(service: service))),
      );
      await tester.enterText(bodyField(), 'Headlines are loud.');
      await tester.tap(find.byKey(const ValueKey('mood-2')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('tag-field')), 'emotion,');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(sent['entryType'], 'QUICK');
      expect(sent['mood'], 2);
      expect(sent['body'], 'Headlines are loud.');
      expect(sent['tags'], ['emotion']);
      expect(sent['contributionId'], isNull);
    });

    testWidgets('tapping the selected mood clears it', (tester) async {
      late Map<String, dynamic> sent;
      final service = serviceWith((req) async {
        sent = jsonDecode(req.body);
        return ok(entryJson(1, 'x'), 201);
      });
      await tester.pumpWidget(
        host(SingleChildScrollView(child: JournalEntrySheet(service: service))),
      );
      await tester.enterText(bodyField(), 'x');
      await tester.tap(find.byKey(const ValueKey('mood-4')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('mood-4')));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(sent['mood'], isNull);
    });

    testWidgets(
      'a monthly check-in is prefilled, tagged and linked to the buy',
      (tester) async {
        late Map<String, dynamic> sent;
        final service = serviceWith((req) async {
          sent = jsonDecode(req.body);
          return ok(entryJson(1, 'x', type: 'CHECKIN'), 201);
        });
        await tester.pumpWidget(
          host(
            SingleChildScrollView(
              child: JournalEntrySheet(
                service: service,
                initialType: JournalEntryType.checkin,
                initialBody: '## Month check-in: October 2026',
                contributionId: 12,
              ),
            ),
          ),
        );
        expect(find.text('#check-in'), findsOneWidget);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(sent['entryType'], 'CHECKIN');
        expect(sent['body'], '## Month check-in: October 2026');
        expect(sent['contributionId'], 12);
        expect(sent['tags'], ['check-in']);
      },
    );

    testWidgets('editing updates the entry and keeps its contribution link', (
      tester,
    ) async {
      late http.Request seen;
      final service = serviceWith((req) async {
        seen = req;
        return ok(entryJson(4, 'edited'));
      });
      final existing = JournalEntryModel.fromJson(
        entryJson(
          4,
          'original',
          type: 'DECISION',
          mood: 3,
          tags: ['decision'],
          contributionId: 8,
        ),
      );
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            child: JournalEntrySheet(existing: existing, service: service),
          ),
        ),
      );
      expect(find.text('Edit entry'), findsOneWidget);
      await tester.enterText(bodyField(), 'edited');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(seen.method, 'PUT');
      expect(seen.url.path, '/api/v1/invest/journal/4');
      final sent = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(sent['entryType'], 'DECISION');
      expect(sent['contributionId'], 8);
      expect(sent['mood'], 3);
    });

    testWidgets('shows a server error and stays open', (tester) async {
      final service = serviceWith(
        (_) async => ok({'message': 'Contribution 9 not found'}, 400),
      );
      await tester.pumpWidget(
        host(SingleChildScrollView(child: JournalEntrySheet(service: service))),
      );
      await tester.enterText(bodyField(), 'x');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Contribution 9 not found'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });

  group('JournalScreen', () {
    Future<void> pumpScreen(WidgetTester tester, JournalService service) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(JournalScreen(service: service)));
      await tester.pumpAndSettle();
    }

    testWidgets('lists entries newest first with tags and count', (
      tester,
    ) async {
      final service = serviceWith((req) async {
        if (req.url.path.endsWith('/tags')) {
          return ok([
            {'name': 'emotion', 'count': 1},
          ]);
        }
        return ok(
          pageJson([
            entryJson(2, 'Second note', tags: ['emotion'], mood: 2),
            entryJson(1, 'First note'),
          ]),
        );
      });
      await pumpScreen(tester, service);
      expect(find.text('Second note', findRichText: true), findsOneWidget);
      expect(find.text('First note', findRichText: true), findsOneWidget);
      expect(find.text('#emotion'), findsOneWidget);
      expect(find.text('Mood 2/5'), findsOneWidget);
      expect(find.text('2 entries'), findsOneWidget);
    });

    testWidgets('shows an empty state, and a different one when filtering', (
      tester,
    ) async {
      final service = serviceWith((req) async {
        if (req.url.path.endsWith('/tags')) return ok([]);
        return ok(pageJson([]));
      });
      await pumpScreen(tester, service);
      expect(find.textContaining('No entries yet'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('filter-QUICK')));
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches those filters'), findsOneWidget);
    });

    testWidgets('type chips and debounced search re-query the server', (
      tester,
    ) async {
      final queries = <Map<String, String>>[];
      final service = serviceWith((req) async {
        if (req.url.path.endsWith('/tags')) return ok([]);
        queries.add(req.url.queryParameters);
        return ok(pageJson([entryJson(1, 'x')]));
      });
      await pumpScreen(tester, service);
      expect(queries.last.containsKey('type'), isFalse);

      await tester.tap(find.byKey(const ValueKey('filter-DECISION')));
      await tester.pumpAndSettle();
      expect(queries.last['type'], 'DECISION');

      final before = queries.length;
      await tester.enterText(find.byKey(const Key('journal-search')), 'loud');
      await tester.pump(const Duration(milliseconds: 100));
      expect(queries.length, before); // still debouncing
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(queries.length, before + 1);
      expect(queries.last['q'], 'loud');
      expect(queries.last['type'], 'DECISION'); // filters combine
    });

    testWidgets('load more appends the next page', (tester) async {
      final service = serviceWith((req) async {
        if (req.url.path.endsWith('/tags')) return ok([]);
        final page = int.parse(req.url.queryParameters['page']!);
        return ok(
          pageJson(
            [entryJson(page + 1, page == 0 ? 'Page one' : 'Page two')],
            page: page,
            total: 2,
            hasMore: page == 0,
          ),
        );
      });
      await pumpScreen(tester, service);
      expect(find.text('Page one', findRichText: true), findsOneWidget);
      await tester.tap(find.byKey(const Key('load-more')));
      await tester.pumpAndSettle();
      expect(find.text('Page one', findRichText: true), findsOneWidget);
      expect(find.text('Page two', findRichText: true), findsOneWidget);
      expect(find.byKey(const Key('load-more')), findsNothing);
    });

    testWidgets('deleting asks first, then removes the entry', (tester) async {
      var deleted = false;
      final service = serviceWith((req) async {
        if (req.url.path.endsWith('/tags')) return ok([]);
        if (req.method == 'DELETE') {
          deleted = true;
          return http.Response('', 204);
        }
        return ok(pageJson(deleted ? [] : [entryJson(1, 'Doomed note')]));
      });
      await pumpScreen(tester, service);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(find.text('Delete entry?'), findsOneWidget);
      expect(deleted, isFalse);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
      expect(find.text('Doomed note', findRichText: true), findsNothing);
    });

    testWidgets('a server error is shown instead of a crash', (tester) async {
      final service = serviceWith((req) async {
        if (req.url.path.endsWith('/tags')) return ok([]);
        return ok({'message': 'boom'}, 500);
      });
      await pumpScreen(tester, service);
      expect(find.text('boom'), findsOneWidget);
    });

    testWidgets(
      'the monthly check-in opens prefilled from the server template',
      (tester) async {
        final service = serviceWith((req) async {
          if (req.url.path.endsWith('/tags')) return ok([]);
          if (req.url.path.endsWith('/checkin-template')) {
            return ok({
              'month': '2026-10',
              'body': '## Month check-in: October 2026',
              'contributionId': 5,
            });
          }
          return ok(pageJson([]));
        });
        await pumpScreen(tester, service);
        await tester.tap(find.text('Monthly check-in'));
        await tester.pumpAndSettle();
        expect(find.text('New entry'), findsOneWidget);
        expect(
          find.text('## Month check-in: October 2026', findRichText: true),
          findsOneWidget,
        );
      },
    );
  });
}
