import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/journal_model.dart';
import 'package:tm_dashboard/screens/invest/journal_entry_sheet.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/journal_service.dart';
import 'package:tm_dashboard/services/plan_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';
import 'package:tm_dashboard/widgets/md_editor_field.dart';

http.Response ok(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> tag(String name, {bool isNew = false, String? reason}) => {
  'kind': 'TAG',
  'tag': name,
  'isNew': isNew,
  'reason': reason ?? 'mentions $name',
};

class Server {
  Server({List<Map<String, dynamic>>? suggestions, this.failStatus})
    : suggestions = suggestions ?? [tag('fear'), tag('waiting', isNew: true)];

  List<Map<String, dynamic>> suggestions;
  int? failStatus;
  final requests = <http.Request>[];
  Map<String, dynamic>? saved;

  Iterable<http.Request> get asks =>
      requests.where((r) => r.url.path.endsWith('/ai/tag-suggestions'));

  ApiClient api() {
    final api = ApiClient(
      client: MockClient((req) async {
        requests.add(req);
        if (req.url.path.endsWith('/ai/tag-suggestions')) {
          if (failStatus != null) {
            return ok({'message': 'AI is switched off'}, failStatus!);
          }
          return ok({'suggestions': suggestions});
        }
        if (req.url.path.endsWith('/journal') && req.method == 'POST') {
          saved = jsonDecode(req.body);
          return ok({
            'id': 1,
            'entryType': 'QUICK',
            'mood': null,
            'body': 'x',
            'tags': <String>[],
            'contributionId': null,
            'createdAt': '2026-10-06T10:00:00',
            'updatedAt': '2026-10-06T10:00:00',
          }, 201);
        }
        return http.Response('not found', 404);
      }),
    );
    addTearDown(api.close);
    return api;
  }
}

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  Finder bodyField() => find.descendant(
    of: find.byType(MdEditorField),
    matching: find.byType(TextField),
  );

  Future<Server> open(
    WidgetTester tester, {
    Server? server,
    JournalEntryType type = JournalEntryType.quick,
  }) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = server ?? Server();
    await tester.pumpWidget(
      host(
        JournalEntrySheet(
          initialType: type,
          service: JournalService(api: s.api()),
          planService: PlanService(api: s.api()),
        ),
      ),
    );
    return s;
  }

  Future<void> suggest(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('suggest-tags')));
    await tester.tap(find.byKey(const Key('suggest-tags')));
    await tester.pumpAndSettle();
  }

  testWidgets('the button says what it sends and nothing is asked on open', (
    tester,
  ) async {
    final s = await open(tester);
    expect(find.byKey(const Key('suggest-tags')), findsOneWidget);
    expect(find.byKey(const Key('suggest-privacy')), findsOneWidget);
    expect(s.asks, isEmpty);
  });

  testWidgets('an empty draft asks for text first and sends nothing', (
    tester,
  ) async {
    final s = await open(tester);
    await suggest(tester);
    expect(find.text('Write something first'), findsOneWidget);
    expect(s.asks, isEmpty);
  });

  testWidgets('sends the draft, its type, mood and current tags', (
    tester,
  ) async {
    final s = await open(tester);
    await tester.enterText(bodyField(), 'I was scared.');
    await tester.tap(find.byKey(const ValueKey('mood-2')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('tag-field')), 'calm,');
    await tester.pump();
    await suggest(tester);
    final body = jsonDecode(s.asks.single.body) as Map<String, dynamic>;
    expect(body['body'], 'I was scared.');
    expect(body['entryType'], 'QUICK');
    expect(body['mood'], 2);
    expect(body['existingTags'], ['calm']);
  });

  testWidgets('the entry type of the sheet is what is sent', (tester) async {
    final s = await open(tester, type: JournalEntryType.decision);
    await tester.enterText(bodyField(), 'text');
    await suggest(tester);
    final body = jsonDecode(s.asks.single.body) as Map<String, dynamic>;
    expect(body['entryType'], 'DECISION');
  });

  testWidgets('suggestions show as chips; new ones say so', (tester) async {
    await open(tester);
    await tester.enterText(bodyField(), 'I was scared.');
    await suggest(tester);
    expect(find.byKey(const Key('suggested-fear')), findsOneWidget);
    expect(find.text('fear'), findsOneWidget);
    expect(find.text('waiting (new)'), findsOneWidget);
  });

  testWidgets('tapping a chip adds the tag to the draft and removes the chip', (
    tester,
  ) async {
    final s = await open(tester);
    await tester.enterText(bodyField(), 'I was scared.');
    await suggest(tester);
    await tester.tap(find.byKey(const Key('suggested-fear')));
    await tester.pump();
    expect(find.byKey(const Key('suggested-fear')), findsNothing);
    expect(find.byKey(const Key('suggested-waiting')), findsOneWidget);
    expect(find.byKey(const ValueKey('tag-fear')), findsOneWidget);
    // Nothing is stored until the entry is saved.
    expect(s.saved, isNull);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(s.saved!['tags'], ['fear']);
  });

  testWidgets('a suggestion for a tag already on the draft is not shown', (
    tester,
  ) async {
    final s = Server(suggestions: [tag('fear'), tag('calm')]);
    await open(tester, server: s);
    await tester.enterText(bodyField(), 'I was scared.');
    await tester.enterText(find.byKey(const Key('tag-field')), 'fear,');
    await tester.pump();
    await suggest(tester);
    expect(find.byKey(const Key('suggested-fear')), findsNothing);
    expect(find.byKey(const Key('suggested-calm')), findsOneWidget);
  });

  testWidgets('no suggestions says so', (tester) async {
    await open(tester, server: Server(suggestions: []));
    await tester.enterText(bodyField(), 'text');
    await suggest(tester);
    expect(find.text('No tag suggestions this time'), findsOneWidget);
  });

  testWidgets('AI being off shows the server message and keeps the draft', (
    tester,
  ) async {
    await open(tester, server: Server(failStatus: 503));
    await tester.enterText(bodyField(), 'text');
    await suggest(tester);
    expect(find.text('AI is switched off'), findsOneWidget);
    expect(find.text('text'), findsOneWidget);
  });
}
