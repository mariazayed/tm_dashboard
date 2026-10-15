import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/screens/invest/insights/insights_screen.dart';
import 'package:tm_dashboard/services/ai_chat_service.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/contribution_service.dart';
import 'package:tm_dashboard/services/journal_service.dart';
import 'package:tm_dashboard/services/learning_service.dart';
import 'package:tm_dashboard/services/plan_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

/// Ten months of a plan, answered like tm-server would. Anything in [failing]
/// answers 500 so one broken source can be checked in isolation.
class FakeServer {
  FakeServer({this.failing = const {}, this.twoFunds = false});

  /// Splits the portfolio into VT (odd months) and AGG (even months).
  final bool twoFunds;

  final Set<String> failing;
  final calls = <String>[];

  static String two(int n) => n.toString().padLeft(2, '0');

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  List<Map<String, dynamic>> _holdings() => [
    for (final (id, t, target, alloc) in [
      (1, 'VT', 60.0, 72.0),
      (2, 'AGG', 40.0, 28.0),
    ])
      {
        'holdingId': id,
        'ticker': t,
        'name': null,
        'assetClass': id == 1 ? 'EQUITY' : 'BONDS',
        'targetPct': target,
        'investedCents': 135000,
        'valueCents': 140000,
        'gainCents': 5000,
        'shares': 12.5,
        'averageCost': 108.0,
        'currentPrice': 112.0,
        'gainPercent': 3.7,
        'allocationPct': alloc,
        'driftPoints': alloc - target,
        'series': [
          for (var m = 1; m <= 9; m++)
            {
              'date': '2026-${two(m)}-10',
              'investedCents': 15000 * m,
              'valueCents': 15000 * m + m * 100 * id,
            },
        ],
      },
  ];

  Future<http.Response> handle(http.Request req) async {
    final path = req.url.path.replaceFirst('/api/v1/invest', '');
    calls.add('${req.method} $path');
    if (failing.contains(path)) {
      return _json({'message': 'boom'}, 500);
    }
    switch (path) {
      case '/settings':
        return _json({
          'monthlyAmountCents': 30000,
          'currency': 'USD',
          'buyDay': 5,
          'ticker': 'VT',
          'startDate': '2026-01-01',
          'timezone': 'UTC',
          'remindersEnabled': true,
          'reminderEmail': 'me@example.com',
          'reminderFollowupDays': 3,
          'ruleWaitHours': 72,
        });
      case '/performance':
        return _json({
          'ticker': 'VT',
          'currency': 'USD',
          'investedCents': 270000,
          'feesCents': 300,
          'shares': 25.0,
          'averageCost': 108.0,
          'currentPrice': 112.0,
          'priceAsOf': '2026-10-10',
          'priceFromCache': true,
          'stale': false,
          'valueCents': 280000,
          'gainCents': 10000,
          'gainPercent': 3.7,
          'range': req.url.queryParameters['range'] ?? 'ALL',
          if (twoFunds) 'holdings': _holdings(),
          'series': [
            for (var m = 1; m <= 9; m++) ...[
              {
                'date': '2026-${two(m)}-10',
                'investedCents': 30000 * m,
                'valueCents': (30000 * m * (1 + m / 200)).round(),
              },
            ],
            {
              'date': '2026-10-10',
              'investedCents': 270000,
              'valueCents': 280000,
            },
          ],
        });
      case '/contributions':
        return _json([
          for (var m = 1; m <= 9; m++)
            if (m != 4)
              {
                'id': m,
                'contributedOn': '2026-${two(m)}-0${m == 3 ? 7 : 5}',
                'amountCents': 30000,
                'shares': 2.8,
                'price': 107.0 + m,
                'feeCents': m == 2 ? 100 : 0,
                if (twoFunds) 'holdingId': m.isEven ? 2 : 1,
                'notes': null,
              },
        ]);
      case '/contributions/status':
        return _json({
          'months': [
            for (var m = 1; m <= 9; m++)
              {
                'month': '2026-${two(m)}',
                'state': m == 4 ? 'MISSED' : 'DONE',
                'contributions': m == 4 ? 0 : 1,
                'totalCents': m == 4 ? 0 : 30000,
              },
            {
              'month': '2026-10',
              'state': 'PENDING',
              'contributions': 0,
              'totalCents': 0,
            },
          ],
          'currentStreak': 5,
          'longestStreak': 5,
          'missedCount': 1,
        });
      case '/settings/changes':
        return _json([
          {
            'field': 'MONTHLY_AMOUNT',
            'oldValue': '25000',
            'newValue': '30000',
            'changedAt': '2026-03-02T08:00:00',
          },
        ]);
      case '/journal':
        return _json({
          'items': [
            {
              'id': 1,
              'entryType': 'CHECKIN',
              'mood': 4,
              'body': 'Fine.',
              'tags': <String>[],
              'contributionId': null,
              'createdAt': '2026-09-03T10:00:00',
            },
            {
              'id': 2,
              'entryType': 'DECISION',
              'mood': 2,
              'body': 'Hold.',
              'tags': <String>[],
              'contributionId': null,
              'createdAt': '2026-04-20T10:00:00',
            },
          ],
          'page': 0,
          'total': 2,
          'hasMore': false,
        });
      case '/ai/rule-check':
        return _json({
          'from': '2025-11-01',
          'to': '2026-10-15',
          'waitHours': 72,
          'findings': [
            {
              'check': 'MISSED_MONTH',
              'date': '2026-04-30',
              'message': 'No buy in April',
              'entryIds': <int>[],
            },
          ],
          'checks': <Object>[],
        });
      case '/learning/cards':
        return _json([
          {
            'id': 1,
            'front': 'a',
            'back': 'b',
            'noteId': null,
            'dueOn': '2026-10-14',
            'intervalDays': 1,
            'repetitions': 0,
            'lapses': 0,
          },
          {
            'id': 2,
            'front': 'c',
            'back': 'd',
            'noteId': null,
            'dueOn': '2026-10-18',
            'intervalDays': 4,
            'repetitions': 3,
            'lapses': 1,
          },
        ]);
      case '/learning/sources':
        return _json([
          {
            'id': 1,
            'title': 'Book',
            'sourceType': 'BOOK',
            'status': 'DONE',
            'url': null,
            'notes': null,
          },
          {
            'id': 2,
            'title': 'Video',
            'sourceType': 'VIDEO',
            'status': 'TO_DO',
            'url': null,
            'notes': null,
          },
        ]);
      case '/reminders':
        return _json({
          'emailConfigured': true,
          'recent': [
            {
              'month': '2026-09',
              'kind': 'DUE',
              'sentAt': '2026-09-05T09:00:00',
            },
          ],
        });
      case '/ai/usage/history':
        return _json({
          'dailyLimit': 60,
          'days': [
            for (var d = 0; d < 30; d++)
              {'date': '2026-09-${two(16 + d % 15)}', 'calls': d % 7},
          ],
        });
    }
    return _json({'message': 'not found: $path'}, 404);
  }
}

Widget screen(FakeServer server) {
  final api = ApiClient(client: MockClient(server.handle));
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: InsightsScreen(
        contributions: ContributionService(api: api),
        plan: PlanService(api: api),
        journal: JournalService(api: api),
        learning: LearningService(api: api),
        ai: AiChatService(api: api),
        now: () => DateTime(2026, 10, 15, 9),
      ),
    ),
  );
}

void main() {
  Future<void> pump(WidgetTester tester, FakeServer server) async {
    tester.view.physicalSize = const Size(1000, 14000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(screen(server));
    await tester.pumpAndSettle();
  }

  const titles = [
    'Invested vs value',
    'Contributions by month',
    'Average cost against price',
    'Did the plan happen?',
    'Fees paid',
    'Shares owned',
    'Each buy on the price line',
    'Planned against actual',
    'Buy timing',
    'Plan changes on the value chart',
    'Best and worst months',
    'Rolling 12-month change',
    'Journal activity',
    'Rules and deviations',
    'Reminders and buys',
    'Flashcards due',
    'Reading list',
    'AI questions per day',
  ];

  testWidgets('draws every chart from the server data', (tester) async {
    final server = FakeServer();
    await pump(tester, server);

    for (final t in titles) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    // No card is stuck loading or showing an error.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Could not load'), findsNothing);
    // Real charts were drawn, not empty states.
    expect(find.byType(LineChart), findsWidgets);
    expect(find.byType(BarChart), findsWidgets);
    // A few summaries computed from the fake data.
    expect(find.textContaining('8 of 9 planned months bought'), findsOneWidget);
    expect(
      find.textContaining('1 finding in 12 months; 11 of 12 months had none'),
      findsOneWidget,
    );
    expect(find.textContaining('Amount \$250.00 to \$300.00'), findsOneWidget);
    expect(
      find.textContaining('1 of 2 reviewed cards have been forgotten'),
      findsNothing,
    );
    expect(
      find.textContaining(
        '1 of 1 reviewed cards have been forgotten at least once',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('1 of 2 finished'), findsOneWidget);
    expect(
      find.textContaining('1 reminder emails in the last 12 months'),
      findsOneWidget,
    );
  });

  testWidgets('each source is requested exactly once', (tester) async {
    final server = FakeServer();
    await pump(tester, server);
    for (final call in [
      'GET /settings',
      'GET /contributions',
      'GET /contributions/status',
      'GET /settings/changes',
      'POST /ai/rule-check',
      'GET /learning/cards',
      'GET /learning/sources',
      'GET /reminders',
      'GET /ai/usage/history',
    ]) {
      expect(server.calls.where((c) => c == call).length, 1, reason: call);
    }
    // Value-over-time is asked for once as ALL, and the page does not refetch on layout changes.
    final perf = server.calls.where((c) => c == 'GET /performance').length;
    expect(perf, 1);
  });

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets('fits $width wide with nothing overflowing', (tester) async {
      tester.view.physicalSize = Size(width, 16000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(screen(FakeServer(twoFunds: width == 320.0)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Did the plan happen?'), findsOneWidget);
    });
  }

  testWidgets(
    'one failing source leaves a note and the other charts still draw',
    (tester) async {
      final server = FakeServer(
        failing: {'/ai/usage/history', '/settings/changes'},
      );
      await pump(tester, server);

      expect(
        find.byKey(const Key('error-AI questions per day')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('error-Plan changes on the value chart')),
        findsOneWidget,
      );
      // Everything else is unaffected.
      expect(find.text('Contributions by month'), findsOneWidget);
      expect(find.text('Did the plan happen?'), findsOneWidget);
      expect(
        find.textContaining('8 of 9 planned months bought'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('error-Contributions by month')),
        findsNothing,
      );
    },
  );

  testWidgets('a brand-new plan with no data shows empty states, not errors', (
    tester,
  ) async {
    final server = _EmptyServer();
    await pump(tester, server);
    expect(find.textContaining('Could not load'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Charts'), findsOneWidget);
  });

  group('with several funds', () {
    testWidgets('a fund picker and the allocation chart appear', (
      tester,
    ) async {
      await pump(tester, FakeServer(twoFunds: true));
      expect(find.byKey(const Key('fund-chip-1')), findsOneWidget);
      expect(find.byKey(const Key('fund-chip-2')), findsOneWidget);
      expect(find.text('Allocation against target'), findsOneWidget);
      expect(find.textContaining('VT, AGG'), findsOneWidget);
      expect(find.byKey(const Key('per-fund-Shares owned')), findsNothing);
      expect(find.textContaining('Could not load'), findsNothing);
    });

    testWidgets('picking a fund redraws the per-fund charts for it', (
      tester,
    ) async {
      await pump(tester, FakeServer(twoFunds: true));
      // First fund by default: 5 odd-month buys (1,3,5,7,9).
      expect(find.textContaining('5 buys'), findsWidgets);
      await tester.tap(find.byKey(const Key('fund-chip-2')));
      await tester.pumpAndSettle();
      // AGG has the even months 2,6,8 (4 is missed): 3 buys.
      expect(find.textContaining('3 buys'), findsWidgets);
    });

    testWidgets('one fund shows neither picker nor allocation chart', (
      tester,
    ) async {
      await pump(tester, FakeServer());
      expect(find.byKey(const Key('fund-chip-1')), findsNothing);
      expect(find.text('Allocation against target'), findsNothing);
    });
  });
}

/// Same API, but nothing has been recorded yet.
class _EmptyServer extends FakeServer {
  @override
  Future<http.Response> handle(http.Request req) async {
    final path = req.url.path.replaceFirst('/api/v1/invest', '');
    switch (path) {
      case '/performance':
        return _ok({
          'ticker': 'VT',
          'currency': 'USD',
          'investedCents': 0,
          'feesCents': 0,
          'shares': 0.0,
          'priceFromCache': false,
          'stale': false,
          'valueCents': 0,
          'gainCents': 0,
          'range': 'ALL',
          'series': <Object>[],
        });
      case '/contributions':
      case '/settings/changes':
      case '/learning/cards':
      case '/learning/sources':
        return _ok(<Object>[]);
      case '/contributions/status':
        return _ok({
          'months': <Object>[],
          'currentStreak': 0,
          'longestStreak': 0,
          'missedCount': 0,
        });
      case '/journal':
        return _ok({
          'items': <Object>[],
          'page': 0,
          'total': 0,
          'hasMore': false,
        });
      case '/ai/rule-check':
        return _ok({
          'from': '2025-11-01',
          'to': '2026-10-15',
          'waitHours': 72,
          'findings': <Object>[],
          'checks': <Object>[],
        });
      case '/reminders':
        return _ok({'emailConfigured': false, 'recent': <Object>[]});
      case '/ai/usage/history':
        return _ok({'dailyLimit': 60, 'days': <Object>[]});
    }
    return super.handle(req);
  }

  static http.Response _ok(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json'},
  );
}
