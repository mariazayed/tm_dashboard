import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/checkin_summary_model.dart';
import 'package:tm_dashboard/screens/invest/ai_review_screen.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/plan_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

http.Response ok(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> summaryJson({
  String month = '2026-10',
  String? text,
  bool requested = false,
  bool ran = false,
  String? reason,
  List<int> sources = const [],
  int skipped = 0,
  int? contributionId = 9,
}) => {
  'kind': 'CHECKIN_SUMMARY',
  'month': month,
  'text': text,
  'facts': {'state': 'DONE'},
  'factsLines': [
    'Month: $month',
    'Planned: 300.00 USD',
    'Invested: 300.00 USD',
  ],
  'sources': sources,
  'contributionId': contributionId,
  'model': {
    'requested': requested,
    'ran': ran,
    'reason': reason,
    'entriesSent': 0,
    'entriesSkipped': skipped,
  },
};

class Server {
  Server({this.configured = true, this.reason});

  bool configured;
  String? reason;
  int? failStatus;
  Map<String, dynamic>? draft;
  final requests = <http.Request>[];

  Iterable<http.Request> get summaries =>
      requests.where((r) => r.url.path.endsWith('/ai/checkin-summary'));
  Iterable<http.Request> get previews =>
      requests.where((r) => r.url.path.endsWith('/ai/context'));

  Map<String, dynamic> body(http.Request r) =>
      jsonDecode(r.body) as Map<String, dynamic>;

  ApiClient api() {
    final api = ApiClient(
      client: MockClient((req) async {
        requests.add(req);
        final path = req.url.path;
        if (path.endsWith('/ai/status')) {
          return ok({
            'configured': configured,
            'model': configured ? 'claude-test' : null,
            'reason': reason,
          });
        }
        if (path.endsWith('/ai/checkin-summary')) {
          if (failStatus != null) {
            return ok({'message': 'Choose a month like 2026-09'}, failStatus!);
          }
          final b = body(req);
          if (b['includeModel'] == true) {
            return ok(draft ?? summaryJson(month: b['month'] as String));
          }
          return ok(summaryJson(month: b['month'] as String));
        }
        if (path.endsWith('/ai/context')) {
          return ok({
            'generatedAt': '2026-10-16T09:30:00Z',
            'includeJournal': true,
            'includeNotes': false,
            'truncated': false,
            'characters': 900,
            'maxCharacters': 20000,
            'text': 'SUMMARY PROMPT',
            'feature': 'checkin',
            'systemPrompt': 'STANDING INSTRUCTIONS',
            'snippets': 2,
          });
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
  home: Scaffold(body: child),
);

void main() {
  final now = DateTime(2026, 10, 16, 9, 30);

  group('model', () {
    test('parses a facts-only reply', () {
      final m = CheckinSummaryModel.fromJson(summaryJson());
      expect(m.month, '2026-10');
      expect(m.state, 'DONE');
      expect(m.factsLines, hasLength(3));
      expect(m.text, isNull);
      expect(m.model.requested, isFalse);
      expect(m.contributionId, 9);
    });

    test('parses a draft with its sources', () {
      final m = CheckinSummaryModel.fromJson(
        summaryJson(
          text: 'A calm month.',
          requested: true,
          ran: true,
          sources: [3, 4],
          skipped: 2,
        ),
      );
      expect(m.text, 'A calm month.');
      expect(m.sources, [3, 4]);
      expect(m.model.ran, isTrue);
      expect(m.model.entriesSkipped, 2);
    });
  });

  group('service', () {
    test('facts only sends just the month', () async {
      final s = Server();
      await PlanService(api: s.api()).checkinSummary(month: '2026-09');
      expect(s.body(s.summaries.single), {'month': '2026-09'});
    });

    test('a draft request carries both switches', () async {
      final s = Server();
      await PlanService(api: s.api()).checkinSummary(
        month: '2026-09',
        includeModel: true,
        includeJournal: false,
      );
      expect(s.body(s.summaries.single), {
        'month': '2026-09',
        'includeModel': true,
        'includeJournal': false,
      });
    });

    test('the preview asks for the checkin feature and month', () async {
      final s = Server();
      await PlanService(
        api: s.api(),
      ).checkinPreview(month: '2026-09', includeJournal: false);
      final q = s.previews.single.url.queryParameters;
      expect(q['feature'], 'checkin');
      expect(q['month'], '2026-09');
      expect(q['includeJournal'], 'false');
    });
  });

  group('screen', () {
    Future<Server> open(WidgetTester tester, {Server? server}) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final s = server ?? Server();
      await tester.pumpWidget(
        host(
          AiReviewScreen(
            service: PlanService(api: s.api()),
            now: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('review-tab-summary')));
      await tester.pumpAndSettle();
      return s;
    }

    testWidgets('shows the facts at once and sends nothing to the AI', (
      tester,
    ) async {
      final s = await open(tester);
      expect(find.byKey(const Key('fact-0')), findsOneWidget);
      expect(find.text('Planned: 300.00 USD'), findsOneWidget);
      expect(s.summaries, hasLength(1));
      final body = s.body(s.summaries.single);
      expect(body['month'], '2026-10');
      expect(body.containsKey('includeModel'), isFalse);
      expect(find.byKey(const Key('summary-text')), findsNothing);
      expect(find.byKey(const Key('summary-reason')), findsNothing);
    });

    testWidgets('the month list is the last six months, newest first', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.byKey(const Key('summary-month')));
      await tester.pumpAndSettle();
      for (final m in [
        '2026-10',
        '2026-09',
        '2026-08',
        '2026-07',
        '2026-06',
        '2026-05',
      ]) {
        expect(find.text(m), findsWidgets);
      }
      expect(find.text('2026-04'), findsNothing);
    });

    testWidgets('choosing another month loads its facts without the AI', (
      tester,
    ) async {
      final s = await open(tester);
      await tester.tap(find.byKey(const Key('summary-month')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2026-08').last);
      await tester.pumpAndSettle();
      final last = s.body(s.summaries.last);
      expect(last['month'], '2026-08');
      expect(last.containsKey('includeModel'), isFalse);
      expect(find.text('Month: 2026-08'), findsOneWidget);
    });

    testWidgets('the draft button is off while AI is not set up', (
      tester,
    ) async {
      await open(
        tester,
        server: Server(configured: false, reason: 'No API key is set.'),
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('summary-draft')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('summary-preview')))
            .onPressed,
        isNull,
      );
      expect(find.textContaining('No API key is set.'), findsOneWidget);
      expect(find.byKey(const Key('fact-0')), findsOneWidget);
    });

    testWidgets('asking for a draft shows it with its sources', (tester) async {
      final s = Server()
        ..draft = summaryJson(
          text: 'You invested the planned amount.',
          requested: true,
          ran: true,
          sources: [3, 4],
          skipped: 1,
        );
      await open(tester, server: s);
      await tester.tap(find.byKey(const Key('summary-draft')));
      await tester.pumpAndSettle();
      final body = s.body(s.summaries.last);
      expect(body['includeModel'], isTrue);
      expect(body['includeJournal'], isTrue);
      expect(find.text('You invested the planned amount.'), findsOneWidget);
      expect(find.text('Drew on entries 3, 4'), findsOneWidget);
      expect(find.byKey(const Key('summary-skipped')), findsOneWidget);
      expect(find.byKey(const Key('summary-use')), findsOneWidget);
      expect(find.byKey(const Key('fact-0')), findsOneWidget);
    });

    testWidgets('turning the journal off is passed on', (tester) async {
      final s = await open(tester);
      await tester.tap(find.byKey(const Key('summary-journal-switch')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('summary-draft')));
      await tester.pumpAndSettle();
      expect(s.body(s.summaries.last)['includeJournal'], isFalse);
    });

    testWidgets(
      'a draft that could not be used shows why and keeps the facts',
      (tester) async {
        final s = Server()
          ..draft = summaryJson(
            requested: true,
            ran: false,
            reason: 'The draft mentioned a number that is not in your facts.',
          );
        await open(tester, server: s);
        await tester.tap(find.byKey(const Key('summary-draft')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('summary-reason')), findsOneWidget);
        expect(find.textContaining('not in your facts'), findsOneWidget);
        expect(find.byKey(const Key('summary-text')), findsNothing);
        expect(find.byKey(const Key('summary-use')), findsNothing);
        expect(find.byKey(const Key('fact-0')), findsOneWidget);
      },
    );

    testWidgets('See what will be sent opens the exact prompt', (tester) async {
      final s = await open(tester);
      await tester.tap(find.byKey(const Key('summary-preview')));
      await tester.pumpAndSettle();
      expect(find.text('What will be sent for this summary'), findsOneWidget);
      final q = s.previews.single.url.queryParameters;
      expect(q['feature'], 'checkin');
      expect(q['month'], '2026-10');
    });

    testWidgets('Use in check-in opens an entry holding the draft', (
      tester,
    ) async {
      final s = Server()
        ..draft = summaryJson(
          text: 'A steady month.',
          requested: true,
          ran: true,
        );
      await open(tester, server: s);
      await tester.tap(find.byKey(const Key('summary-draft')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('summary-use')));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == 'A steady month.',
        ),
        findsOneWidget,
      );
      // Opening the sheet saves nothing.
      expect(
        s.requests.where(
          (r) => r.method == 'POST' && r.url.path.endsWith('/journal'),
        ),
        isEmpty,
      );
    });

    testWidgets('a bad month shows the server message', (tester) async {
      final s = Server()..failStatus = 400;
      await open(tester, server: s);
      expect(find.byKey(const Key('summary-error')), findsOneWidget);
      expect(find.byKey(const Key('fact-0')), findsNothing);
    });

    testWidgets('the rule check tab is still the first tab', (tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final s = Server();
      await tester.pumpWidget(
        host(
          AiReviewScreen(
            service: PlanService(api: s.api()),
            now: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('review-run')), findsOneWidget);
    });
  });
}
