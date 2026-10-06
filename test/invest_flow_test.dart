import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/screens/invest/contributions_screen.dart';
import 'package:tm_dashboard/screens/invest/invest_home_screen.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/contribution_service.dart';
import 'package:tm_dashboard/services/plan_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

/// A small in-memory stand-in for tm-server that behaves like the real one for the
/// parts this flow touches: it keeps contributions, and derives the status and the
/// performance from them. The screens, services, models and the shared ApiClient
/// (with its read cache) are all the real thing.
class FakeInvestServer {
  final contributions = <Map<String, dynamic>>[];
  int _nextId = 1;
  int failNextCreateWith = 0;
  final calls = <String>[];

  static final _month = DateTime.now().toUtc();
  static String get currentMonth =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<http.Response> handle(http.Request req) async {
    final path = req.url.path.replaceFirst('/api/v1/invest', '');
    calls.add('${req.method} $path');

    if (path == '/settings') {
      return _json({
        'monthlyAmountCents': 30000,
        'currency': 'USD',
        'buyDay': 1,
        'ticker': 'VT',
        'startDate': '2026-01-01',
        'timezone': 'UTC',
        'remindersEnabled': false,
        'reminderEmail': null,
        'reminderFollowupDays': 3,
      });
    }
    if (path == '/rules') {
      return _json([
        {'id': 1, 'text': 'Never sell in a crash.', 'position': 1},
      ]);
    }
    if (path == '/contributions' && req.method == 'GET') {
      return _json(contributions.reversed.toList());
    }
    if (path == '/contributions' && req.method == 'POST') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      if (failNextCreateWith != 0) {
        final code = failNextCreateWith;
        failNextCreateWith = 0;
        return _json({'message': 'Shares do not match amount / price'}, code);
      }
      final row = {
        'id': _nextId++,
        'contributedOn': body['contributedOn'],
        'amountCents': body['amountCents'],
        'shares': body['shares'],
        'price': body['price'],
        'feeCents': body['feeCents'] ?? 0,
        'notes': body['notes'],
      };
      contributions.add(row);
      return _json(row, 201);
    }
    final del = RegExp(r'^/contributions/(\d+)$').firstMatch(path);
    if (del != null && req.method == 'DELETE') {
      contributions.removeWhere((c) => c['id'] == int.parse(del.group(1)!));
      return http.Response('', 204);
    }
    if (path == '/contributions/status') return _json(_status());
    if (path == '/performance') return _json(_performance());
    return _json({'message': 'not found: ${req.method} $path'}, 404);
  }

  Map<String, dynamic> _status() {
    final done = contributions.isNotEmpty;
    return {
      'months': [
        {
          'month': currentMonth,
          'state': done ? 'DONE' : 'PENDING',
          'contributions': contributions.length,
          'totalCents': contributions.fold<int>(
            0,
            (a, c) => a + (c['amountCents'] as int),
          ),
        },
      ],
      'currentStreak': done ? 1 : 0,
      'longestStreak': done ? 1 : 0,
      'missedCount': 0,
      'currentDueDate': '$currentMonth-28',
      'daysUntilDue': 5,
    };
  }

  Map<String, dynamic> _performance() {
    final invested = contributions.fold<int>(
      0,
      (a, c) => a + (c['amountCents'] as int) + (c['feeCents'] as int),
    );
    final shares = contributions.fold<double>(
      0,
      (a, c) => a + (c['shares'] as num),
    );
    final price = contributions.isEmpty
        ? null
        : (contributions.last['price'] as num).toDouble();
    final value = price == null ? 0 : (shares * price * 100).round();
    return {
      'ticker': 'VT',
      'currency': 'USD',
      'investedCents': invested,
      'feesCents': 0,
      'shares': shares,
      'averageCost': invested == 0 ? null : invested / 100 / shares,
      'currentPrice': price,
      'priceAsOf': contributions.isEmpty
          ? null
          : contributions.last['contributedOn'],
      'priceFromCache': false,
      'stale': false,
      'valueCents': value,
      'gainCents': value - invested,
      'gainPercent': invested == 0 ? null : (value - invested) * 100 / invested,
      'range': 'ALL',
      'series': contributions.isEmpty
          ? []
          : [
              {
                'date': contributions.last['contributedOn'],
                'investedCents': invested,
                'valueCents': value,
              },
            ],
    };
  }
}

void main() {
  late FakeInvestServer server;
  late ContributionService contributions;
  late PlanService plan;

  setUp(() {
    server = FakeInvestServer();
    // One shared client, as in the app: this is what makes the read cache matter.
    final api = ApiClient(client: MockClient(server.handle));
    addTearDown(api.close);
    contributions = ContributionService(api: api);
    plan = PlanService(api: api);
  });

  Future<void> show(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox()); // always a fresh State
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openHome(WidgetTester tester) =>
      show(tester, InvestHomeScreen(contributions: contributions, plan: plan));

  Future<void> openContributions(WidgetTester tester) =>
      show(tester, ContributionsScreen(service: contributions));

  Future<void> addBuy(WidgetTester tester, {String price = '120'}) async {
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price per VT share'),
      price,
    );
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'an empty plan shows nothing invested and this month still to do',
    (tester) async {
      await openHome(tester);
      expect(find.text('Invest'), findsOneWidget);
      expect(
        find.textContaining(r'$300.00 / month into VT, on day 1'),
        findsOneWidget,
      );
      expect(find.text(r'$0.00'), findsWidgets); // invested and value
      expect(find.text('This month: due in 5 days'), findsOneWidget);
      expect(
        find.text('Never sell in a crash.'),
        findsOneWidget,
      ); // the rules card
      expect(
        find.text('Add a contribution to see performance'),
        findsOneWidget,
      );
    },
  );

  testWidgets('recording a buy changes what the dashboard shows', (
    tester,
  ) async {
    await openHome(tester); // loads and caches the empty numbers
    expect(find.text('This month: due in 5 days'), findsOneWidget);

    await openContributions(tester);
    await addBuy(tester); // $300 at $120 -> 2.5 shares
    expect(server.contributions, hasLength(1));
    expect(
      jsonDecode(jsonEncode(server.contributions.single))['amountCents'],
      30000,
    );
    expect(
      find.textContaining(r'$300.00'),
      findsWidgets,
    ); // the new row in the list

    // Back on the dashboard, within the cache window: it must not show stale zeros.
    await openHome(tester);
    expect(find.text('This month: done'), findsOneWidget);
    expect(find.text(r'$300.00'), findsWidgets); // invested and value
    expect(find.text('Month streak'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Add a contribution to see performance'), findsNothing);
  });

  testWidgets('deleting the buy takes the dashboard back to empty', (
    tester,
  ) async {
    await openContributions(tester);
    await addBuy(tester);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(server.contributions, isEmpty);
    expect(find.text('No contributions yet'), findsOneWidget);

    await openHome(tester);
    expect(find.text('This month: due in 5 days'), findsOneWidget);
    expect(find.text('Add a contribution to see performance'), findsOneWidget);
  });

  testWidgets(
    'a rejected buy is explained and changes nothing on the dashboard',
    (tester) async {
      await openHome(tester);
      await openContributions(tester);
      server.failNextCreateWith = 400;
      await addBuy(tester);
      expect(
        find.text('Shares do not match amount / price'),
        findsOneWidget,
      ); // the sheet stays open with the reason
      expect(server.contributions, isEmpty);

      await tester.tap(
        find.byKey(const Key('form-error')),
      ); // keep the sheet; now dismiss it
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await openHome(tester);
      expect(find.text('This month: due in 5 days'), findsOneWidget);
    },
  );

  testWidgets('the dashboard reads each piece it needs exactly once per load', (
    tester,
  ) async {
    await openHome(tester);
    expect(server.calls.where((c) => c == 'GET /settings'), hasLength(1));
    expect(
      server.calls.where((c) => c == 'GET /contributions/status'),
      hasLength(1),
    );
    expect(server.calls.where((c) => c == 'GET /performance'), hasLength(1));
    expect(server.calls.where((c) => c == 'GET /rules'), hasLength(1));
  });
}
