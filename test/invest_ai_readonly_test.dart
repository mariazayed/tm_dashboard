import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/journal_model.dart';
import 'package:tm_dashboard/screens/invest/ai_chat_screen.dart';
import 'package:tm_dashboard/screens/invest/ai_review_screen.dart';
import 'package:tm_dashboard/screens/invest/journal_entry_sheet.dart';
import 'package:tm_dashboard/services/ai_chat_service.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/journal_service.dart';
import 'package:tm_dashboard/services/plan_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';
import 'package:tm_dashboard/widgets/md_editor_field.dart';

/// The AI features only suggest. Whatever the user does on an AI screen,
/// short of saving an entry themselves, the app may only read and may only
/// POST to /ai/... endpoints (which never store journal data). These tests
/// drive each flow to its end and check every request it made.
http.Response ok(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

class Recorder {
  final requests = <http.Request>[];

  /// Anything that could change the owner's data.
  List<String> get writes => [
    for (final r in requests)
      if (r.method != 'GET' &&
          !(r.method == 'POST' && r.url.path.contains('/ai/')))
        '${r.method} ${r.url.path}',
  ];

  int get aiPosts => requests
      .where((r) => r.method == 'POST' && r.url.path.contains('/ai/'))
      .length;

  ApiClient api() {
    final api = ApiClient(
      client: MockClient((req) async {
        requests.add(req);
        final path = req.url.path;
        if (path.endsWith('/ai/status')) {
          return ok({'configured': true, 'model': 'claude-test'});
        }
        if (path.endsWith('/ai/usage')) {
          return ok({
            'date': '2026-10-06',
            'callsToday': 1,
            'dailyLimit': 60,
            'perMinuteLimit': 6,
            'inputTokens': 1,
            'outputTokens': 1,
            'callsByFeature': {'CHAT': 1},
          });
        }
        if (path.endsWith('/ai/chat')) {
          return ok({
            'answer': 'You felt scared [J12].',
            'sources': [
              {
                'handle': 'J12',
                'type': 'JOURNAL',
                'id': 12,
                'date': '2026-03-04',
                'snippet': 'I was scared.',
              },
            ],
            'usedJournal': true,
            'usedNotes': true,
            'truncated': false,
            'cutOff': false,
            'model': 'claude-test',
            'refusal': null,
          });
        }
        if (path.endsWith('/ai/rule-check')) {
          return ok({
            'from': '2026-09-17',
            'to': '2026-10-16',
            'waitHours': 72,
            'findings': [
              {
                'check': 'MODEL_REVIEW',
                'source': 'MODEL',
                'date': '2026-10-05',
                'message': 'The entry records selling during a crash.',
                'entryIds': [12],
                'ruleId': 7,
                'quote': 'sold everything',
                'confidence': 'HIGH',
              },
            ],
            'checks': [],
            'model': {
              'requested': true,
              'ran': true,
              'reason': null,
              'entriesChecked': 1,
              'entriesSkipped': 0,
              'dropped': 0,
            },
          });
        }
        if (path.endsWith('/ai/checkin-summary')) {
          final b = jsonDecode(req.body) as Map<String, dynamic>;
          final draft = b['includeModel'] == true;
          return ok({
            'kind': 'CHECKIN_SUMMARY',
            'month': b['month'],
            'text': draft ? 'A steady month.' : null,
            'facts': {'state': 'DONE'},
            'factsLines': ['Planned: 300.00 USD'],
            'sources': draft ? [12] : [],
            'contributionId': 9,
            'model': {
              'requested': draft,
              'ran': draft,
              'reason': null,
              'entriesSent': 1,
              'entriesSkipped': 0,
            },
          });
        }
        if (path.endsWith('/ai/tag-suggestions')) {
          return ok({
            'suggestions': [
              {'kind': 'TAG', 'tag': 'fear', 'isNew': false, 'reason': 'x'},
            ],
          });
        }
        if (path.endsWith('/rules')) return ok(<Object>[]);
        return http.Response('not found', 404);
      }),
    );
    addTearDown(api.close);
    return api;
  }
}

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  final now = DateTime(2026, 10, 16, 9, 30);

  testWidgets('asking the chat a question only reads and posts to /ai', (
    tester,
  ) async {
    tall(tester);
    final r = Recorder();
    await tester.pumpWidget(
      host(
        AiChatScreen(
          service: AiChatService(api: r.api()),
          planService: PlanService(api: r.api()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('chat-input')), 'scared?');
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('source-J12')));
    await tester.pumpAndSettle();
    expect(r.aiPosts, 1);
    expect(r.writes, isEmpty);
  });

  testWidgets('the rule check with AI, then a reflection, writes nothing', (
    tester,
  ) async {
    tall(tester);
    final r = Recorder();
    await tester.pumpWidget(
      host(
        AiReviewScreen(
          service: PlanService(api: r.api()),
          now: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-ai-switch')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('review-run')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-preview')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5)); // close the preview
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-reflection')).first);
    await tester.pumpAndSettle();
    expect(find.byType(JournalEntrySheet), findsOneWidget);
    expect(r.aiPosts, 1);
    expect(r.writes, isEmpty);
  });

  testWidgets('a summary draft and Use in check-in write nothing', (
    tester,
  ) async {
    tall(tester);
    final r = Recorder();
    await tester.pumpWidget(
      host(
        AiReviewScreen(
          service: PlanService(api: r.api()),
          now: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-tab-summary')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('summary-draft')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('summary-use')));
    await tester.pumpAndSettle();
    expect(find.byType(JournalEntrySheet), findsOneWidget);
    expect(r.aiPosts, 2); // the facts, then the draft
    expect(r.writes, isEmpty);
  });

  testWidgets('suggesting tags and taking one writes nothing until Save', (
    tester,
  ) async {
    tall(tester);
    final r = Recorder();
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: JournalEntrySheet(
            service: JournalService(api: r.api()),
            planService: PlanService(api: r.api()),
            initialType: JournalEntryType.quick,
          ),
        ),
      ),
    );
    await tester.enterText(
      find.descendant(
        of: find.byType(MdEditorField),
        matching: find.byType(TextField),
      ),
      'I was scared.',
    );
    await tester.tap(find.byKey(const Key('suggest-tags')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('suggested-fear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tag-fear')), findsOneWidget);
    expect(r.aiPosts, 1);
    expect(r.writes, isEmpty);
  });

  test('the recorder itself flags writes', () {
    final r = Recorder();
    r.requests
      ..add(http.Request('POST', Uri.parse('http://x/api/v1/invest/ai/chat')))
      ..add(http.Request('POST', Uri.parse('http://x/api/v1/invest/journal')))
      ..add(http.Request('PUT', Uri.parse('http://x/api/v1/invest/ai/x')))
      ..add(
        http.Request('DELETE', Uri.parse('http://x/api/v1/invest/rules/1')),
      );
    expect(r.writes, [
      'POST /api/v1/invest/journal',
      'PUT /api/v1/invest/ai/x',
      'DELETE /api/v1/invest/rules/1',
    ]);
  });
}
