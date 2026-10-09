import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/rule_check_model.dart';
import 'package:tm_dashboard/screens/invest/ai_review_screen.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/plan_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

http.Response ok(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> exactFinding() => {
  'check': 'WAIT_PERIOD',
  'source': 'DETERMINISTIC',
  'date': '2026-10-02',
  'message':
      'Entry 2 (2026-10-02) records a deviation only 24 hours after the decision in entry 1 (2026-10-01). Your wait is 72 hours.',
  'entryIds': [1, 2],
  'ruleId': null,
  'quote': null,
  'confidence': 'HIGH',
};

Map<String, dynamic> modelFinding({
  int ruleId = 7,
  String message = 'The entry records selling during a crash.',
  String? quote = 'sold everything in the crash',
  String confidence = 'HIGH',
  List<int> entryIds = const [12],
  String date = '2026-10-05',
}) => {
  'check': 'MODEL_REVIEW',
  'source': 'MODEL',
  'date': date,
  'message': message,
  'entryIds': entryIds,
  'ruleId': ruleId,
  'quote': quote,
  'confidence': confidence,
};

Map<String, dynamic> modelInfo({
  bool requested = true,
  bool ran = true,
  String? reason,
  int checked = 3,
  int skipped = 0,
  int dropped = 0,
}) => {
  'requested': requested,
  'ran': ran,
  'reason': reason,
  'entriesChecked': checked,
  'entriesSkipped': skipped,
  'dropped': dropped,
};

Map<String, dynamic> resultJson({
  List<Map<String, dynamic>> findings = const [],
  Map<String, dynamic>? model,
  List<Map<String, dynamic>>? checks,
}) => {
  'from': '2026-09-17',
  'to': '2026-10-16',
  'waitHours': 72,
  'findings': findings,
  'checks':
      checks ??
      [
        {
          'code': 'WAIT_PERIOD',
          'label': 'Wait before a deviation',
          'status': 'RAN',
          'note': null,
        },
      ],
  'model': model ?? modelInfo(requested: false, ran: false),
};

class Server {
  Server({
    this.configured = true,
    this.reason,
    Future<http.Response> Function(http.Request)? check,
  }) : checkHandler = check ?? ((_) async => ok(resultJson()));

  bool configured;
  String? reason;
  Future<http.Response> Function(http.Request) checkHandler;
  final requests = <http.Request>[];

  Iterable<http.Request> get checks =>
      requests.where((r) => r.url.path.endsWith('/ai/rule-check'));
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
        if (path.endsWith('/ai/rule-check')) return checkHandler(req);
        if (path.endsWith('/rules')) {
          return ok([
            {
              'id': 5,
              'text': 'Wait 72 hours before any deviation.',
              'position': 1,
            },
            {'id': 7, 'text': 'Never sell in a crash.', 'position': 2},
          ]);
        }
        if (path.endsWith('/ai/context')) {
          return ok({
            'generatedAt': '2026-10-16T09:30:00Z',
            'includeJournal': true,
            'includeNotes': false,
            'truncated': false,
            'characters': 5100,
            'maxCharacters': 20000,
            'text': 'JOURNAL CHECK PROMPT',
            'feature': 'rulecheck',
            'systemPrompt': 'STANDING INSTRUCTIONS',
            'snippets': 3,
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

  group('models and service', () {
    test(
      'an AI finding keeps its rule, quote and source; an old one defaults',
      () {
        final f = RuleFindingModel.fromJson(modelFinding());
        expect(f.isModel, isTrue);
        expect(f.ruleId, 7);
        expect(f.quote, 'sold everything in the crash');
        expect(f.confidence, 'HIGH');

        final old = RuleFindingModel.fromJson({
          'check': 'WAIT_PERIOD',
          'date': '2026-10-02',
          'message': 'm',
        });
        expect(old.isModel, isFalse);
        expect(old.ruleId, isNull);
        expect(old.quote, isNull);
      },
    );

    test('the model info parses, and a server without it gives null', () {
      final r = RuleCheckModel.fromJson(
        resultJson(model: modelInfo(skipped: 2, dropped: 1, reason: null)),
      );
      expect(r.model!.requested, isTrue);
      expect(r.model!.entriesSkipped, 2);
      expect(r.model!.dropped, 1);
      final bare = RuleCheckModel.fromJson({
        'from': 'a',
        'to': 'b',
        'waitHours': 1,
      });
      expect(bare.model, isNull);
    });

    test('the AI reading is requested only when asked for', () async {
      final s = Server();
      final plan = PlanService(api: s.api());
      await plan.ruleCheck(
        from: DateTime(2026, 9, 17),
        to: DateTime(2026, 10, 16),
      );
      expect(s.body(s.checks.last), {'from': '2026-09-17', 'to': '2026-10-16'});
      await plan.ruleCheck(
        from: DateTime(2026, 9, 17),
        to: DateTime(2026, 10, 16),
        includeModel: true,
      );
      expect(s.body(s.checks.last), {
        'from': '2026-09-17',
        'to': '2026-10-16',
        'includeModel': true,
      });
    });

    test(
      'the check preview asks for the journal check prompt of the range',
      () async {
        final s = Server();
        final p = await PlanService(api: s.api()).ruleCheckPreview(
          from: DateTime(2026, 9, 17),
          to: DateTime(2026, 10, 16),
        );
        final q = s.previews.single.url.queryParameters;
        expect(q, {
          'feature': 'rulecheck',
          'from': '2026-09-17',
          'to': '2026-10-16',
        });
        expect(p.feature, 'rulecheck');
        expect(p.snippets, 3);
      },
    );
  });

  group('screen', () {
    Future<Server> open(
      WidgetTester tester, {
      Server? server,
      int width = 900,
    }) async {
      tester.view.physicalSize = Size(width.toDouble(), 2400);
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
      return s;
    }

    Future<void> run(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('review-run')));
      await tester.pumpAndSettle();
    }

    Future<void> enableAi(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('review-ai-switch')));
      await tester.pump();
    }

    testWidgets(
      'starts on 30 days with the AI reading off and the disclaimer showing',
      (tester) async {
        await open(tester);
        expect(
          tester.widget<ChoiceChip>(find.byKey(const Key('range-30'))).selected,
          isTrue,
        );
        expect(
          tester
              .widget<SwitchListTile>(find.byKey(const Key('review-ai-switch')))
              .value,
          isFalse,
        );
        expect(find.byKey(const Key('review-disclaimer')), findsOneWidget);
        expect(
          find.byKey(const Key('review-exact-clear')),
          findsNothing,
          reason: 'nothing run yet',
        );
      },
    );

    testWidgets('the exact check alone never asks for the AI reading', (
      tester,
    ) async {
      final s = await open(
        tester,
        server: Server(
          check: (_) async => ok(resultJson(findings: [exactFinding()])),
        ),
      );
      await run(tester);
      expect(s.body(s.checks.single), {
        'from': '2026-09-17',
        'to': '2026-10-16',
      });
      expect(find.byKey(const Key('exact-0')), findsOneWidget);
      expect(
        find.textContaining('records a deviation only 24 hours'),
        findsOneWidget,
      );
      expect(find.text('AI reading'), findsNothing);
    });

    testWidgets('says so when the exact checks find nothing', (tester) async {
      await open(tester);
      await run(tester);
      expect(find.byKey(const Key('review-exact-clear')), findsOneWidget);
    });

    testWidgets('the range chips change the dates asked for', (tester) async {
      final s = await open(tester);
      await tester.tap(find.byKey(const Key('range-7')));
      await tester.pump();
      await run(tester);
      expect(s.body(s.checks.last)['from'], '2026-10-10');
      await tester.tap(find.byKey(const Key('range-90')));
      await tester.pump();
      await run(tester);
      expect(s.body(s.checks.last)['from'], '2026-07-19');
    });

    testWidgets('when AI is not set up the switch is off and says why', (
      tester,
    ) async {
      final s = await open(
        tester,
        server: Server(
          configured: false,
          reason: 'AI is switched off. Set ai.enabled=true on the server',
        ),
      );
      expect(find.textContaining('Set ai.enabled=true'), findsOneWidget);
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('review-ai-switch')))
            .onChanged,
        isNull,
      );
      await run(tester);
      expect(s.body(s.checks.single).containsKey('includeModel'), isFalse);
    });

    testWidgets(
      'switching the AI reading on says what is sent and asks for it',
      (tester) async {
        final s = await open(tester);
        expect(
          find.textContaining('text of the journal entries'),
          findsOneWidget,
        );
        await enableAi(tester);
        await run(tester);
        expect(s.body(s.checks.single)['includeModel'], isTrue);
      },
    );

    testWidgets(
      'AI findings show the rule, the reason, the quote and the entries',
      (tester) async {
        await open(
          tester,
          server: Server(
            check: (_) async => ok(
              resultJson(
                findings: [exactFinding(), modelFinding()],
                model: modelInfo(checked: 3),
              ),
            ),
          ),
        );
        await enableAi(tester);
        await run(tester);
        expect(find.text('AI reading'), findsOneWidget);
        expect(find.text('Read 3 journal entries.'), findsOneWidget);
        expect(find.byKey(const Key('model-0')), findsOneWidget);
        expect(find.text('HIGH confidence'), findsOneWidget);
        expect(find.text('Rule 2: Never sell in a crash.'), findsOneWidget);
        expect(
          find.text('The entry records selling during a crash.'),
          findsOneWidget,
        );
        expect(find.text('“sold everything in the crash”'), findsOneWidget);
        expect(find.text('Entry 12'), findsOneWidget);
        expect(
          find.byKey(const Key('exact-0')),
          findsOneWidget,
          reason: 'exact findings stay in their own list',
        );
      },
    );

    testWidgets('low-confidence suggestions are hidden until asked for', (
      tester,
    ) async {
      await open(
        tester,
        server: Server(
          check: (_) async => ok(
            resultJson(
              findings: [
                modelFinding(
                  confidence: 'MEDIUM',
                  message: 'Probably conflicts.',
                ),
                modelFinding(
                  confidence: 'LOW',
                  message: 'Might conflict.',
                  quote: null,
                ),
              ],
              model: modelInfo(),
            ),
          ),
        ),
      );
      await enableAi(tester);
      await run(tester);
      expect(find.text('Probably conflicts.'), findsOneWidget);
      expect(find.text('Might conflict.'), findsNothing);
      await tester.tap(find.byKey(const Key('review-show-low')));
      await tester.pump();
      expect(find.text('Might conflict.'), findsOneWidget);
      expect(find.text('Hide low-confidence suggestions'), findsOneWidget);
      await tester.tap(find.byKey(const Key('review-show-low')));
      await tester.pump();
      expect(find.text('Might conflict.'), findsNothing);
    });

    testWidgets(
      'no conflicts found, with notes about what was left out or discarded',
      (tester) async {
        await open(
          tester,
          server: Server(
            check: (_) async => ok(
              resultJson(model: modelInfo(checked: 40, skipped: 5, dropped: 2)),
            ),
          ),
        );
        await enableAi(tester);
        await run(tester);
        expect(find.byKey(const Key('review-model-clear')), findsOneWidget);
        expect(
          find.textContaining(
            'Read 40 journal entries. 5 older entries were left out',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('2 suggestions were discarded'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'when the AI part could not run, the reason shows and the exact result stays',
      (tester) async {
        await open(
          tester,
          server: Server(
            check: (_) async => ok(
              resultJson(
                findings: [exactFinding()],
                model: modelInfo(
                  ran: false,
                  checked: 0,
                  reason:
                      'The daily AI limit (60 calls) is used up. It resets at midnight UTC.',
                ),
              ),
            ),
          ),
        );
        await enableAi(tester);
        await run(tester);
        expect(find.byKey(const Key('review-ai-reason')), findsOneWidget);
        expect(find.textContaining('daily AI limit'), findsOneWidget);
        expect(find.byKey(const Key('exact-0')), findsOneWidget);
      },
    );

    testWidgets(
      'see what will be sent previews the check prompt and sends nothing to the AI',
      (tester) async {
        final s = await open(tester);
        expect(
          tester
              .widget<TextButton>(find.byKey(const Key('review-preview')))
              .onPressed,
          isNull,
          reason: 'only meaningful once the AI reading is on',
        );
        await enableAi(tester);
        await tester.tap(find.byKey(const Key('review-preview')));
        await tester.pumpAndSettle();
        final q = s.previews.single.url.queryParameters;
        expect(q['feature'], 'rulecheck');
        expect(q['from'], '2026-09-17');
        expect(q['to'], '2026-10-16');
        expect(find.text('What will be sent for this check'), findsOneWidget);
        expect(find.text('JOURNAL CHECK PROMPT'), findsOneWidget);
        expect(
          find.byKey(const Key('include-journal')),
          findsNothing,
          reason: 'the check always reads the journal',
        );
        expect(find.textContaining('3 journal entries'), findsOneWidget);
        expect(s.checks, isEmpty);
      },
    );

    testWidgets(
      'add a reflection opens the entry sheet with the finding and the rule',
      (tester) async {
        await open(
          tester,
          server: Server(
            check: (_) async =>
                ok(resultJson(findings: [modelFinding()], model: modelInfo())),
          ),
        );
        await enableAi(tester);
        await run(tester);
        await tester.ensureVisible(find.byKey(const Key('add-reflection')));
        await tester.tap(find.byKey(const Key('add-reflection')));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            'I noticed: The entry records selling during a crash.',
          ),
          findsWidgets,
        );
        expect(
          find.textContaining('The rule says: Never sell in a crash.'),
          findsWidgets,
        );
        expect(find.textContaining('What I will do next time:'), findsWidgets);
      },
    );

    testWidgets('an error is shown and the check can be run again', (
      tester,
    ) async {
      var fail = true;
      final s = await open(
        tester,
        server: Server(
          check: (_) async => fail
              ? ok({'message': 'Choose a range of at most 92 days'}, 400)
              : ok(resultJson(findings: [exactFinding()])),
        ),
      );
      await run(tester);
      expect(find.text('Choose a range of at most 92 days'), findsOneWidget);
      fail = false;
      await run(tester);
      expect(find.byKey(const Key('review-error')), findsNothing);
      expect(find.byKey(const Key('exact-0')), findsOneWidget);
      expect(s.checks.length, 2);
    });

    testWidgets('an unreachable server is a message, not a crash', (
      tester,
    ) async {
      await open(
        tester,
        server: Server(check: (_) async => throw http.ClientException('down')),
      );
      await run(tester);
      expect(find.text('Could not reach the server'), findsOneWidget);
    });

    for (final width in [320, 390]) {
      testWidgets('fits a $width wide screen with long AI findings', (
        tester,
      ) async {
        await open(
          tester,
          width: width,
          server: Server(
            check: (_) async => ok(
              resultJson(
                findings: [
                  exactFinding(),
                  for (var i = 0; i < 4; i++)
                    modelFinding(
                      message: 'A long reason ${'word ' * 50}',
                      quote: 'a long quote ${'word ' * 30}',
                      entryIds: [for (var j = 1; j <= 12; j++) 1000 + j],
                    ),
                ],
                model: modelInfo(checked: 40, skipped: 3, dropped: 2),
              ),
            ),
          ),
        );
        await enableAi(tester);
        await run(tester);
        expect(tester.takeException(), isNull, reason: 'no overflow at $width');
      });
    }
  });
}
