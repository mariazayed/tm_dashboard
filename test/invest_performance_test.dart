import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/performance_model.dart';
import 'package:tm_dashboard/screens/invest/performance_card.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/contribution_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

Map<String, dynamic> performanceJson([
  Map<String, dynamic> overrides = const {},
]) => {
  'ticker': 'VT',
  'currency': 'USD',
  'investedCents': 60100,
  'feesCents': 100,
  'shares': 5.5,
  'averageCost': 109.2727,
  'currentPrice': 130.0,
  'priceAsOf': '2026-09-10',
  'priceFromCache': true,
  'stale': false,
  'valueCents': 71500,
  'gainCents': 11400,
  'gainPercent': 18.97,
  'range': 'ALL',
  'series': [
    {'date': '2026-08-01', 'investedCents': 30000, 'valueCents': 30000},
    {'date': '2026-09-10', 'investedCents': 60100, 'valueCents': 71500},
  ],
  ...overrides,
};

PerformanceModel model([Map<String, dynamic> overrides = const {}]) =>
    PerformanceModel.fromJson(performanceJson(overrides));

ContributionService serviceWith(
  Future<http.Response> Function(http.Request) handler,
) {
  final api = ApiClient(client: MockClient(handler));
  addTearDown(api.close);
  return ContributionService(api: api);
}

void main() {
  group('PerformanceModel', () {
    test('parses totals and series', () {
      final p = model();
      expect(p.investedCents, 60100);
      expect(p.gainPercent, 18.97);
      expect(p.priceAsOf, DateTime(2026, 9, 10));
      expect(p.series.last.valueCents, 71500);
      expect(p.hasContributions, isTrue);
    });

    test('tolerates a portfolio with nothing invested', () {
      final p = model({
        'investedCents': 0,
        'feesCents': 0,
        'shares': 0,
        'averageCost': null,
        'currentPrice': null,
        'priceAsOf': null,
        'priceFromCache': false,
        'valueCents': 0,
        'gainCents': 0,
        'gainPercent': null,
        'series': [],
      });
      expect(p.hasContributions, isFalse);
      expect(p.gainPercent, isNull);
      expect(p.series, isEmpty);
    });

    test('refresh result separates success from a provider failure', () {
      final ok = PriceRefreshResult.fromJson({
        'inserted': 3,
        'updated': 1,
        'latestDate': '2026-10-14',
        'error': null,
      });
      expect(ok.ok, isTrue);
      final failed = PriceRefreshResult.fromJson({
        'inserted': 0,
        'updated': 0,
        'latestDate': '2026-10-09',
        'error': 'HTTP 429',
      });
      expect(failed.ok, isFalse);
      expect(failed.error, 'HTTP 429');
    });
  });

  group('ContributionService performance calls', () {
    test('requests the chosen range', () async {
      late Uri seen;
      final service = serviceWith((req) async {
        seen = req.url;
        return http.Response(jsonEncode(performanceJson({'range': '1Y'})), 200);
      });
      final p = await service.getPerformance(range: '1Y');
      expect(seen.path, '/api/v1/invest/performance');
      expect(seen.queryParameters['range'], '1Y');
      expect(p.range, '1Y');
    });

    test('refreshPrices posts and reads the result body', () async {
      late http.Request seen;
      final service = serviceWith((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'fetched': 4,
            'inserted': 4,
            'updated': 0,
            'latestDate': '2026-10-14',
            'error': null,
          }),
          200,
        );
      });
      final r = await service.refreshPrices();
      expect(seen.method, 'POST');
      expect(seen.url.path, '/api/v1/invest/prices/refresh');
      expect(r.inserted, 4);
    });
  });

  group('PerformanceCard', () {
    test('formats gains with a sign and a percentage', () {
      expect(PerformanceCard.gainText(model()), r'+$114.00 (+18.97%)');
      expect(
        PerformanceCard.gainText(
          model({'gainCents': -3000, 'gainPercent': -10.0}),
        ),
        r'-$30.00 (-10.00%)',
      );
      expect(
        PerformanceCard.gainText(model({'gainCents': 0, 'gainPercent': null})),
        r'$0.00',
      );
    });

    test('price note says how fresh the price is', () {
      expect(
        PerformanceCard.priceNote(model()),
        contains('VT \$130.00 as of Sep 10, 2026'),
      );
      expect(
        PerformanceCard.priceNote(model({'stale': true})),
        contains('out of date'),
      );
      expect(
        PerformanceCard.priceNote(model({'priceFromCache': false})),
        contains('No market prices yet'),
      );
      expect(
        PerformanceCard.priceNote(model({'investedCents': 0})),
        'Add a contribution to see performance',
      );
    });

    Future<void> pump(
      WidgetTester tester,
      PerformanceModel p, {
      VoidCallback? onRefresh,
      bool refreshing = false,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: PerformanceCard(
              performance: p,
              onRefresh: onRefresh ?? () {},
              refreshing: refreshing,
            ),
          ),
        ),
      );
    }

    testWidgets('shows the figures and refreshes on tap', (tester) async {
      var taps = 0;
      await pump(tester, model(), onRefresh: () => taps++);
      expect(find.text(r'$601.00'), findsOneWidget); // invested
      expect(find.text(r'$715.00'), findsOneWidget); // value
      expect(find.byKey(const Key('gain-figure')), findsOneWidget);
      await tester.tap(find.text('Refresh prices'));
      expect(taps, 1);
    });

    testWidgets('disables the button while refreshing', (tester) async {
      var taps = 0;
      await pump(tester, model(), onRefresh: () => taps++, refreshing: true);
      await tester.tap(find.text('Refreshing…'));
      expect(taps, 0);
    });
  });
}
