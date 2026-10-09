import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/contribution_model.dart';
import 'package:tm_dashboard/models/invest/contribution_status_model.dart';
import 'package:tm_dashboard/models/invest/invest_settings_model.dart';
import 'package:tm_dashboard/models/invest/money.dart';
import 'package:tm_dashboard/screens/invest/add_contribution_sheet.dart';
import 'package:tm_dashboard/screens/invest/contribution_status_card.dart';
import 'package:tm_dashboard/screens/invest/contributions_screen.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/contribution_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

final settings = InvestSettingsModel(
  monthlyAmountCents: 30000,
  currency: 'USD',
  buyDay: 1,
  ticker: 'VT',
  startDate: DateTime(2026, 8, 1),
);

ContributionStatusModel statusJson(Map<String, dynamic> overrides) =>
    ContributionStatusModel.fromJson({
      'months': [
        {
          'month': '2026-09',
          'state': 'DONE',
          'contributions': 1,
          'totalCents': 30000,
        },
        {
          'month': '2026-10',
          'state': 'PENDING',
          'contributions': 0,
          'totalCents': 0,
        },
      ],
      'currentStreak': 1,
      'longestStreak': 2,
      'missedCount': 0,
      'currentDueDate': '2026-10-15',
      'daysUntilDue': 5,
      ...overrides,
    });

ContributionService serviceWith(
  Future<http.Response> Function(http.Request) handler,
) {
  final api = ApiClient(client: MockClient(handler));
  addTearDown(api.close);
  return ContributionService(api: api);
}

void main() {
  group('Money', () {
    test('parses decimal text to cents without floating point', () {
      expect(Money.parseCents('300'), 30000);
      expect(Money.parseCents('300.5'), 30050);
      expect(Money.parseCents(r' $1,200.07 '), 120007);
      expect(Money.parseCents('0.10'), 10);
    });

    test('rejects junk, negatives and sub-cent precision', () {
      for (final bad in ['', 'abc', '-5', '1.234', '1.2.3', '12,34,5x']) {
        expect(Money.parseCents(bad), isNull, reason: bad);
      }
    });

    test('formats and linked math', () {
      expect(Money.plain(30000), '300.00');
      expect(Money.format(123456, 'USD'), r'$1,234.56');
      expect(ContributionMath.sharesFor(30000, 120), 2.5);
      expect(ContributionMath.priceFor(30000, 2.5), 120);
      expect(ContributionMath.sharesFor(30000, 0), isNull);
    });
  });

  group('models', () {
    test('contribution parses and formats dates', () {
      final c = ContributionModel.fromJson({
        'id': 3,
        'contributedOn': '2026-10-01',
        'amountCents': 30000,
        'shares': 2.55489022,
        'price': 117.425,
        'feeCents': 0,
        'notes': null,
      });
      expect(c.contributedOn, DateTime(2026, 10, 1));
      expect(ContributionModel.dateString(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('status parses states and tolerates a plan that has not started', () {
      final s = statusJson({});
      expect(s.current!.state, MonthState.pending);
      expect(s.months.first.state, MonthState.done);
      final empty = ContributionStatusModel.fromJson({
        'months': [],
        'currentStreak': 0,
        'longestStreak': 0,
        'missedCount': 0,
        'currentDueDate': null,
        'daysUntilDue': null,
      });
      expect(empty.current, isNull);
    });
  });

  group('ContributionService', () {
    test('create posts cents and returns the saved row', () async {
      late http.Request seen;
      final service = serviceWith((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'id': 1,
            'contributedOn': '2026-10-01',
            'amountCents': 30000,
            'shares': 2.55,
            'price': 117.6,
            'feeCents': 0,
            'notes': null,
          }),
          201,
        );
      });
      final saved = await service.create({'amountCents': 30000});
      expect(saved.id, 1);
      expect(seen.method, 'POST');
      expect(seen.url.path, '/api/v1/invest/contributions');
      expect(jsonDecode(seen.body)['amountCents'], 30000);
    });

    test('surfaces validation and business errors from the server', () async {
      final service = serviceWith(
        (_) async => http.Response(
          jsonEncode({'message': 'Contribution date cannot be in the future'}),
          400,
        ),
      );
      await expectLater(
        service.create({}),
        throwsA(
          isA<InvestApiException>().having(
            (e) => e.message,
            'message',
            'Contribution date cannot be in the future',
          ),
        ),
      );

      final fieldErrors = serviceWith(
        (_) async => http.Response(
          jsonEncode({
            'validationErrors': [
              {'field': 'amountCents', 'message': 'must be greater than 0'},
            ],
          }),
          400,
        ),
      );
      await expectLater(
        fieldErrors.create({}),
        throwsA(
          isA<InvestApiException>().having(
            (e) => e.message,
            'message',
            'amountCents: must be greater than 0',
          ),
        ),
      );
    });

    test('import sends text/csv and reads a 422 as row errors', () async {
      late http.Request seen;
      final service = serviceWith((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'imported': 0,
            'skipped': 0,
            'errors': [
              {'line': 3, 'message': 'Date must be YYYY-MM-DD'},
            ],
          }),
          422,
        );
      });
      final result = await service.importCsv('date,amount\nx');
      expect(seen.headers['Content-Type'], contains('text/csv'));
      expect(seen.body, 'date,amount\nx');
      expect(result.ok, isFalse);
      expect(result.errors.single, 'Line 3: Date must be YYYY-MM-DD');
    });

    test('import success reports counts', () async {
      final service = serviceWith(
        (_) async => http.Response(
          jsonEncode({'imported': 2, 'skipped': 1, 'errors': []}),
          200,
        ),
      );
      final result = await service.importCsv('x');
      expect(result.ok, isTrue);
      expect(result.imported, 2);
      expect(result.skipped, 1);
    });
  });

  group('status card', () {
    test('headline covers every state', () {
      String h(String state, int? days, [String? month]) =>
          ContributionStatusCard.headline(
            statusJson({
              'months': [
                {
                  'month': '2026-10',
                  'state': state,
                  'contributions': 0,
                  'totalCents': 0,
                },
              ],
              'daysUntilDue': days,
            }),
          );
      expect(h('DONE', 3), 'This month: done');
      expect(h('PENDING', 5), 'This month: due in 5 days');
      expect(h('PENDING', 1), 'This month: due in 1 day');
      expect(h('PENDING', 0), 'This month: due today');
      expect(h('OVERDUE', -2), 'This month: overdue by 2 days');
      expect(h('MISSED', -40), 'This month: missed');
    });

    testWidgets('shows headline, streaks and a chip per month', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: ContributionStatusCard(status: statusJson({}))),
        ),
      );
      expect(find.text('This month: due in 5 days'), findsOneWidget);
      expect(find.text('Best streak'), findsOneWidget);
      expect(find.byKey(const Key('month-2026-09')), findsOneWidget);
      expect(find.byKey(const Key('month-2026-10')), findsOneWidget);
    });
  });

  group('add contribution sheet', () {
    Future<void> open(WidgetTester tester, ContributionService service) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AddContributionSheet(settings: settings, service: service),
          ),
        ),
      );
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    testWidgets('prefills the monthly amount and derives shares from price', (
      tester,
    ) async {
      await open(tester, serviceWith((_) async => http.Response('{}', 500)));

      expect(
        tester.widget<TextFormField>(field('Amount (USD)')).controller!.text,
        '300.00',
      );
      await tester.enterText(field('Price per VT share'), '120');
      await tester.pump();
      expect(
        tester.widget<TextFormField>(field('Shares')).controller!.text,
        '2.50000000',
      );
    });

    testWidgets('a hand-typed share count is not overwritten', (tester) async {
      await open(tester, serviceWith((_) async => http.Response('{}', 500)));
      await tester.enterText(field('Shares'), '2.4');
      await tester.enterText(field('Price per VT share'), '120');
      await tester.pump();
      expect(
        tester.widget<TextFormField>(field('Shares')).controller!.text,
        '2.4',
      );
    });

    testWidgets('rejects a bad amount without calling the server', (
      tester,
    ) async {
      var calls = 0;
      await open(
        tester,
        serviceWith((_) async {
          calls++;
          return http.Response('{}', 500);
        }),
      );
      await tester.enterText(field('Amount (USD)'), '12.345');
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(find.byKey(const Key('form-error')), findsOneWidget);
      expect(calls, 0);
    });

    testWidgets('saves cents, shares and price, and shows a server error', (
      tester,
    ) async {
      http.Request? seen;
      await open(
        tester,
        serviceWith((req) async {
          seen = req;
          return http.Response(
            jsonEncode({'message': 'Shares do not match amount / price'}),
            400,
          );
        }),
      );
      await tester.enterText(field('Price per VT share'), '120');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final body = jsonDecode(seen!.body) as Map<String, dynamic>;
      expect(body['amountCents'], 30000);
      expect(body['price'], 120);
      expect(body['shares'], 2.5);
      expect(body['feeCents'], 0);
      expect(find.text('Shares do not match amount / price'), findsOneWidget);
    });
  });

  group('ContributionsScreen CSV import', () {
    testWidgets('pasting CSV posts it and the dialog closes cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      http.Request? imported;
      final service = serviceWith((req) async {
        if (req.method == 'POST' && req.url.path.endsWith('/import')) {
          imported = req;
          return http.Response(
            jsonEncode({'imported': 2, 'skipped': 0, 'errors': []}),
            200,
          );
        }
        if (req.url.path.endsWith('/settings')) {
          return http.Response(
            jsonEncode({
              'monthlyAmountCents': 30000,
              'currency': 'USD',
              'buyDay': 1,
              'ticker': 'VT',
              'startDate': '2026-08-01',
            }),
            200,
          );
        }
        return http.Response('[]', 200);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: ContributionsScreen(service: service)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Import CSV'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('csv-input')),
        'date,amount,shares,price\n2026-09-01,300,2.55,117.64',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      expect(imported, isNotNull);
      expect(imported!.headers['Content-Type'], contains('text/csv'));
      expect(imported!.body, startsWith('date,amount,shares,price'));
      expect(find.byKey(const Key('csv-input')), findsNothing); // dialog gone
      expect(
        tester.takeException(),
        isNull,
      ); // no "controller used after dispose"
    });

    testWidgets('cancelling imports nothing', (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var posts = 0;
      final service = serviceWith((req) async {
        if (req.method == 'POST') posts++;
        if (req.url.path.endsWith('/settings')) {
          return http.Response(
            jsonEncode({
              'monthlyAmountCents': 30000,
              'currency': 'USD',
              'buyDay': 1,
              'ticker': 'VT',
              'startDate': '2026-08-01',
            }),
            200,
          );
        }
        return http.Response('[]', 200);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: ContributionsScreen(service: service)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import CSV'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(posts, 0);
      expect(tester.takeException(), isNull);
    });
  });
}
