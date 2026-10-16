import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/models/invest/holding_model.dart';
import 'package:tm_dashboard/models/invest/invest_settings_model.dart';
import 'package:tm_dashboard/models/invest/performance_model.dart';
import 'package:tm_dashboard/screens/invest/add_contribution_sheet.dart';
import 'package:tm_dashboard/screens/invest/funds_section.dart';
import 'package:tm_dashboard/screens/invest/performance_card.dart';
import 'package:tm_dashboard/services/api_client.dart';
import 'package:tm_dashboard/services/holding_service.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

Map<String, dynamic> fund(int id, String ticker, num target) => {
  'id': id,
  'ticker': ticker,
  'name': null,
  'assetClass': id == 1 ? 'EQUITY' : 'BONDS',
  'region': 'Global',
  'targetPct': target,
  'expenseRatio': null,
  'notes': null,
};

http.Response ok(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> holdingPerf(
  int id,
  String ticker,
  double target,
  double alloc,
  double drift,
) => {
  'holdingId': id,
  'ticker': ticker,
  'name': null,
  'assetClass': 'EQUITY',
  'targetPct': target,
  'investedCents': 10000,
  'valueCents': 12000,
  'gainCents': 2000,
  'shares': 1.0,
  'averageCost': 100.0,
  'currentPrice': 120.0,
  'gainPercent': 20.0,
  'allocationPct': alloc,
  'driftPoints': drift,
  'series': [],
};

Map<String, dynamic> perfJson(List<Map<String, dynamic>> holdings) => {
  'ticker': holdings.length > 1 ? 'MIXED' : 'VT',
  'currency': 'USD',
  'investedCents': 20000,
  'feesCents': 0,
  'shares': 2.0,
  'averageCost': holdings.length > 1 ? null : 100.0,
  'currentPrice': holdings.length > 1 ? null : 120.0,
  'priceAsOf': '2026-09-10',
  'priceFromCache': true,
  'stale': false,
  'valueCents': 24000,
  'gainCents': 4000,
  'gainPercent': 20.0,
  'range': 'ALL',
  'series': [],
  'holdings': holdings,
};

final settings = InvestSettingsModel(
  monthlyAmountCents: 30000,
  currency: 'USD',
  buyDay: 1,
  ticker: 'VT',
  startDate: DateTime(2026, 8, 1),
);

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(800, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  group('FundsSection', () {
    late List<http.Request> sent;
    late List<Map<String, dynamic>> funds;

    HoldingService service({int? createStatus}) {
      sent = [];
      final api = ApiClient(
        client: MockClient((req) async {
          sent.add(req);
          if (req.method == 'POST') {
            if (createStatus == 400) {
              return ok({'message': 'Targets add up to 140%'}, 400);
            }
            funds.add(fund(2, 'AGG', 40));
            return ok(funds.last, 201);
          }
          if (req.method == 'DELETE') {
            funds.removeLast();
            return http.Response('', 204);
          }
          return ok(funds);
        }),
      );
      addTearDown(api.close);
      return HoldingService(api: api);
    }

    testWidgets('lists funds; one fund cannot be removed', (tester) async {
      tall(tester);
      funds = [fund(1, 'VT', 100)];
      await tester.pumpWidget(host(FundsSection(service: service())));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fund-1')), findsOneWidget);
      expect(find.byKey(const Key('targets-total')), findsNothing);
      expect(
        tester
            .widget<IconButton>(find.byKey(const Key('delete-fund-1')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('adds a fund with the remaining target suggested', (
      tester,
    ) async {
      tall(tester);
      funds = [fund(1, 'VT', 60)];
      await tester.pumpWidget(host(FundsSection(service: service())));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-fund')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('fund-target')))
            .controller!
            .text,
        '40',
      );
      await tester.enterText(find.byKey(const Key('fund-ticker')), 'agg');
      await tester.tap(find.byKey(const Key('save-fund')));
      await tester.pumpAndSettle();
      final body =
          jsonDecode(sent.firstWhere((r) => r.method == 'POST').body)
              as Map<String, dynamic>;
      expect(body['ticker'], 'AGG');
      expect(body['targetPct'], 40);
      expect(find.byKey(const Key('fund-2')), findsOneWidget);
      expect(find.byKey(const Key('targets-total')), findsOneWidget);
    });

    testWidgets('shows the server message when a fund is refused', (
      tester,
    ) async {
      tall(tester);
      funds = [fund(1, 'VT', 100)];
      await tester.pumpWidget(
        host(FundsSection(service: service(createStatus: 400))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-fund')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('fund-ticker')), 'AGG');
      await tester.tap(find.byKey(const Key('save-fund')));
      await tester.pumpAndSettle();
      expect(find.text('Targets add up to 140%'), findsOneWidget);
    });
  });

  group('AddContributionSheet fund picker', () {
    final two = [
      HoldingModel.fromJson(fund(1, 'VT', 60)),
      HoldingModel.fromJson(fund(2, 'AGG', 40)),
    ];

    testWidgets('is hidden with one fund and shown with several', (
      tester,
    ) async {
      tall(tester);
      await tester.pumpWidget(
        host(AddContributionSheet(settings: settings, holdings: [two.first])),
      );
      expect(find.byKey(const Key('fund-picker')), findsNothing);
      await tester.pumpWidget(
        host(
          AddContributionSheet(
            settings: settings,
            holdings: two,
            defaultHoldingId: 2,
          ),
        ),
      );
      expect(find.byKey(const Key('fund-picker')), findsOneWidget);
      expect(find.text('Price per share'), findsOneWidget);
    });
  });

  group('PerformanceCard with several funds', () {
    testWidgets('shows a per-fund breakdown and flags drift', (tester) async {
      tall(tester);
      final p = PerformanceModel.fromJson(
        perfJson([
          holdingPerf(1, 'VT', 60, 70, 10),
          holdingPerf(2, 'AGG', 40, 30, -10),
        ]),
      );
      expect(p.isMixed, isTrue);
      await tester.pumpWidget(
        host(PerformanceCard(performance: p, onRefresh: () {})),
      );
      expect(find.byKey(const Key('fund-breakdown')), findsOneWidget);
      expect(find.byKey(const Key('fund-row-1')), findsOneWidget);
      expect(find.byKey(const Key('fund-row-2')), findsOneWidget);
      expect(find.byKey(const Key('drift-1')), findsOneWidget);
    });

    testWidgets('a single fund shows no breakdown', (tester) async {
      tall(tester);
      final p = PerformanceModel.fromJson(
        perfJson([holdingPerf(1, 'VT', 100, 100, 0)]),
      );
      expect(p.isMixed, isFalse);
      await tester.pumpWidget(
        host(PerformanceCard(performance: p, onRefresh: () {})),
      );
      expect(find.byKey(const Key('fund-breakdown')), findsNothing);
    });
  });
}
