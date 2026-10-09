import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/rule_check_model.dart';
import 'package:tm_dashboard/screens/invest/consistency_card.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/contribution_service.dart';
import 'package:tm_dashboard/services/plan_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

http.Response ok(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> findingJson({
  String check = 'WAIT_PERIOD',
  String date = '2026-10-02',
  String message =
      'Entry 2 (2026-10-02) records a deviation only 24 hours after the decision in entry 1 (2026-10-01). Your wait is 72 hours.',
  List<int> entryIds = const [1, 2],
}) => {
  'check': check,
  'source': 'DETERMINISTIC',
  'date': date,
  'message': message,
  'entryIds': entryIds,
  'ruleId': null,
  'quote': null,
  'confidence': 'HIGH',
};

Map<String, dynamic> resultJson({
  List<Map<String, dynamic>> findings = const [],
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
        {
          'code': 'PLAN_CHANGE',
          'label': 'Plan changed without a note',
          'status': 'RAN',
          'note': null,
        },
      ],
};

class Server {
  Server(this.handler);

  final Future<http.Response> Function(http.Request) handler;
  final requests = <http.Request>[];

  ApiClient api() {
    final api = ApiClient(
      client: MockClient((req) {
        requests.add(req);
        return handler(req);
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
  final now = DateTime(2026, 10, 16, 9, 30);

  group('model and service', () {
    test('a result parses, including findings and which checks ran', () {
      final r = RuleCheckModel.fromJson(
        resultJson(
          findings: [findingJson()],
          checks: [
            {
              'code': 'WAIT_PERIOD',
              'label': 'Wait before a deviation',
              'status': 'OFF',
              'note': 'Switched off: the wait is set to 0 hours in Settings.',
            },
          ],
        ),
      );
      expect(r.waitHours, 72);
      expect(r.findings.single.check, 'WAIT_PERIOD');
      expect(r.findings.single.entryIds, [1, 2]);
      expect(r.findings.single.confidence, 'HIGH');
      expect(r.checks.single.isOff, isTrue);
      expect(r.checks.single.note, contains('0 hours'));
    });

    test('missing lists are empty rather than an error', () {
      final r = RuleCheckModel.fromJson({
        'from': '2026-09-17',
        'to': '2026-10-16',
        'waitHours': 0,
      });
      expect(r.findings, isEmpty);
      expect(r.checks, isEmpty);
    });

    test('the request carries the two dates and nothing else', () async {
      final s = Server((_) async => ok(resultJson()));
      await PlanService(
        api: s.api(),
      ).ruleCheck(from: DateTime(2026, 9, 7), to: DateTime(2026, 10, 6));
      final req = s.requests.single;
      expect(req.method, 'POST');
      expect(req.url.path, endsWith('/ai/rule-check'));
      expect(jsonDecode(req.body), {'from': '2026-09-07', 'to': '2026-10-06'});
    });

    test('a server error keeps its message and status', () async {
      final s = Server(
        (_) async => ok({'message': 'Choose a range of at most 92 days'}, 400),
      );
      await expectLater(
        PlanService(
          api: s.api(),
        ).ruleCheck(from: DateTime(2026, 1, 1), to: DateTime(2026, 10, 6)),
        throwsA(
          isA<InvestApiException>()
              .having((e) => e.statusCode, 'status', 400)
              .having((e) => e.message, 'message', contains('92 days')),
        ),
      );
    });
  });

  group('card', () {
    Future<Server> open(
      WidgetTester tester,
      Future<http.Response> Function(http.Request) handler, {
      int days = 30,
    }) async {
      final s = Server(handler);
      await tester.pumpWidget(
        host(
          ConsistencyCard(
            service: PlanService(api: s.api()),
            now: () => now,
            days: days,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return s;
    }

    testWidgets('asks for the last 30 days, counting today', (tester) async {
      final s = await open(tester, (_) async => ok(resultJson()));
      final body = jsonDecode(s.requests.single.body) as Map<String, dynamic>;
      expect(body['to'], '2026-10-16');
      expect(body['from'], '2026-09-17'); // 30 days including the 16th
    });

    testWidgets('says so when there is nothing to flag', (tester) async {
      await open(tester, (_) async => ok(resultJson()));
      expect(find.byKey(const Key('consistency-clear')), findsOneWidget);
      expect(find.byKey(const Key('finding-0')), findsNothing);
      expect(find.byKey(const Key('consistency-error')), findsNothing);
    });

    testWidgets('lists each finding with its date, newest first as sent', (
      tester,
    ) async {
      await open(
        tester,
        (_) async => ok(
          resultJson(
            findings: [
              findingJson(
                check: 'PLAN_CHANGE',
                date: '2026-10-12',
                message:
                    'The plan was changed on 2026-10-12 (ticker VT to VTI), with no journal entry in the 7 days before it.',
              ),
              findingJson(),
            ],
          ),
        ),
      );
      expect(find.byKey(const Key('consistency-clear')), findsNothing);
      expect(
        find.textContaining('2026-10-12: The plan was changed on 2026-10-12'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          '2026-10-02: Entry 2 (2026-10-02) records a deviation',
        ),
        findsOneWidget,
      );
      final first = tester.getTopLeft(find.byKey(const Key('finding-0'))).dy;
      final second = tester.getTopLeft(find.byKey(const Key('finding-1'))).dy;
      expect(first, lessThan(second));
    });

    testWidgets('a check that is off says why', (tester) async {
      await open(
        tester,
        (_) async => ok(
          resultJson(
            checks: [
              {
                'code': 'WAIT_PERIOD',
                'label': 'Wait before a deviation',
                'status': 'OFF',
                'note': 'Switched off: the wait is set to 0 hours in Settings.',
              },
              {
                'code': 'PLAN_CHANGE',
                'label': 'Plan changed without a note',
                'status': 'RAN',
                'note': null,
              },
            ],
          ),
        ),
      );
      expect(
        find.text(
          'Wait before a deviation: Switched off: the wait is set to 0 hours in Settings.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('check-off-PLAN_CHANGE')), findsNothing);
    });

    testWidgets('always explains how the checks read your journal', (
      tester,
    ) async {
      await open(tester, (_) async => ok(resultJson()));
      expect(find.byKey(const Key('consistency-help')), findsOneWidget);
      expect(
        find.textContaining('prompts to look, not verdicts'),
        findsOneWidget,
      );
    });

    testWidgets('an error is shown in place and the card can try again', (
      tester,
    ) async {
      var fail = true;
      final s = await open(
        tester,
        (_) async => fail
            ? ok({'message': 'Something went wrong'}, 500)
            : ok(resultJson(findings: [findingJson()])),
      );
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byKey(const Key('finding-0')), findsNothing);

      fail = false;
      await tester.tap(find.byKey(const Key('consistency-refresh')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('consistency-error')), findsNothing);
      expect(find.byKey(const Key('finding-0')), findsOneWidget);
      expect(s.requests.length, 2);
    });

    testWidgets('an unreachable server is a message, not a crash', (
      tester,
    ) async {
      await open(tester, (_) async => throw http.ClientException('down'));
      expect(find.text('Could not reach the server'), findsOneWidget);
    });

    testWidgets('shows progress while it loads and disables refresh', (
      tester,
    ) async {
      final slow = Completer<http.Response>();
      final s = Server((_) => slow.future);
      await tester.pumpWidget(
        host(
          ConsistencyCard(
            service: PlanService(api: s.api()),
            now: () => now,
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('consistency-loading')), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('consistency-refresh')))
            .onPressed,
        isNull,
      );
      slow.complete(ok(resultJson()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('consistency-loading')), findsNothing);
    });

    testWidgets('a late answer for a card that has been replaced is ignored', (
      tester,
    ) async {
      final first = Completer<http.Response>();
      var calls = 0;
      final s = Server((_) {
        calls++;
        return calls == 1
            ? first.future
            : Future.value(
                ok(
                  resultJson(findings: [findingJson(message: 'NEWER ANSWER')]),
                ),
              );
      });
      await tester.pumpWidget(
        host(
          ConsistencyCard(
            service: PlanService(api: s.api()),
            now: () => now,
          ),
        ),
      );
      await tester.pump();
      // Refresh is disabled while loading, so the way to get a second load is a new card.
      await tester.pumpWidget(
        host(
          ConsistencyCard(
            key: const ValueKey('second'),
            service: PlanService(api: s.api()),
            now: () => now,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('NEWER ANSWER'), findsOneWidget);
      first.complete(
        ok(resultJson(findings: [findingJson(message: 'OLDER ANSWER')])),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('OLDER ANSWER'), findsNothing);
      expect(find.textContaining('NEWER ANSWER'), findsOneWidget);
    });

    for (final width in [320.0, 390.0]) {
      testWidgets('fits a $width wide screen with long messages', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await open(
          tester,
          (_) async => ok(
            resultJson(
              findings: [
                for (var i = 0; i < 6; i++)
                  findingJson(message: 'A long message ${'word ' * 60}'),
              ],
              checks: [
                {
                  'code': 'WAIT_PERIOD',
                  'label': 'Wait before a deviation',
                  'status': 'OFF',
                  'note': 'Switched off: ${'because ' * 20}',
                },
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'no overflow at $width');
      });
    }
  });
}
