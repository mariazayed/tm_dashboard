import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tm_dashboard/models/invest/performance_model.dart';
import 'package:tm_dashboard/models/invest/projection.dart';
import 'package:tm_dashboard/screens/invest/performance_card.dart';
import 'package:tm_dashboard/screens/invest/projection_panel.dart';
import 'package:tm_dashboard/screens/invest/value_chart_card.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

PerformanceModel perf({
  String range = 'ALL',
  List<Map<String, dynamic>>? series,
}) => PerformanceModel.fromJson({
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
  'range': range,
  'series':
      series ??
      [
        {'date': '2026-08-01', 'investedCents': 30000, 'valueCents': 30000},
        {'date': '2026-08-15', 'investedCents': 30000, 'valueCents': 33000},
        {'date': '2026-09-10', 'investedCents': 60100, 'valueCents': 71500},
      ],
});

Widget host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('Projection maths', () {
    // Reference values computed independently (python) with an effective annual
    // rate converted to a monthly rate, contributions at month end.
    int fv(int start, int monthly, int years, double r) => Projection.compute(
      startCents: start,
      monthlyCents: monthly,
      years: years,
      annualReturn: r,
    ).finalValueCents;

    test('matches independently computed values', () {
      expect(fv(0, 30000, 10, 0.07), 5131552);
      expect(fv(0, 30000, 10, 0.05), 4630895);
      expect(fv(0, 30000, 10, 0.09), 5691560);
      expect(fv(0, 30000, 1, 0.07), 371409);
      expect(fv(100000, 30000, 10, 0.07), 5328267);
      expect(fv(500000, 0, 5, 0.07), 701276);
    });

    test('zero return is just the money put in', () {
      final p = Projection.compute(
        startCents: 100000,
        monthlyCents: 30000,
        years: 10,
        annualReturn: 0,
      );
      expect(p.finalValueCents, 100000 + 30000 * 120);
      expect(p.growthCents, 0);
    });

    test('contributed includes the starting balance; growth is the rest', () {
      final p = Projection.compute(
        startCents: 100000,
        monthlyCents: 30000,
        years: 10,
        annualReturn: 0.07,
      );
      expect(p.contributedCents, 100000 + 30000 * 120);
      expect(p.growthCents, p.finalValueCents - p.contributedCents);
      expect(p.growthCents, greaterThan(0));
    });

    test('zero years leaves the starting balance untouched', () {
      final p = Projection.compute(
        startCents: 12345,
        monthlyCents: 30000,
        years: 0,
        annualReturn: 0.07,
      );
      expect(p.finalValueCents, 12345);
      expect(p.contributedCents, 12345);
    });

    test('a higher return never gives less', () {
      expect(fv(0, 30000, 20, 0.09), greaterThan(fv(0, 30000, 20, 0.07)));
      expect(fv(0, 30000, 20, 0.07), greaterThan(fv(0, 30000, 20, 0.05)));
    });
  });

  group('ProjectionPanel', () {
    testWidgets('shows three scenarios for the default horizon', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const ProjectionPanel(
            startCents: 0,
            monthlyCents: 30000,
            currency: 'USD',
          ),
        ),
      );
      expect(find.byKey(const ValueKey('scenario-5')), findsOneWidget);
      expect(find.byKey(const ValueKey('scenario-7')), findsOneWidget);
      expect(find.byKey(const ValueKey('scenario-9')), findsOneWidget);
      expect(find.text(r'$51,315.52'), findsOneWidget); // 7%, 10 years
      expect(find.text(r'$36,000.00'), findsNWidgets(3)); // put in, every row
      expect(find.textContaining('not predictions'), findsOneWidget);
    });

    testWidgets('responds to the monthly amount and the years slider', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const ProjectionPanel(
            startCents: 0,
            monthlyCents: 30000,
            currency: 'USD',
          ),
        ),
      );
      tester
          .widget<Slider>(find.byKey(const Key('projection-years')))
          .onChanged!(1);
      await tester.pump();
      expect(find.text('Years: 1'), findsOneWidget);
      expect(find.text(r'$3,714.09'), findsOneWidget); // 7%, 1 year

      await tester.enterText(
        find.byKey(const Key('projection-monthly')),
        '100',
      );
      await tester.pump();
      expect(find.text(r'$1,200.00'), findsNWidgets(3)); // 100 * 12 put in
    });

    testWidgets('stacks the scenarios on a phone-width screen', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          const ProjectionPanel(
            startCents: 0,
            monthlyCents: 30000,
            currency: 'USD',
          ),
        ),
      );
      expect(find.byType(Table), findsNothing);
      expect(find.text('7% a year'), findsOneWidget);
      expect(find.text(r'$51,315.52'), findsOneWidget);
      expect(
        find.text(r'Put in $36,000.00 · growth $15,315.52'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull); // no overflow
    });

    testWidgets('ignores an invalid amount instead of crashing', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const ProjectionPanel(
            startCents: 0,
            monthlyCents: 30000,
            currency: 'USD',
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('projection-monthly')),
        'abc',
      );
      await tester.pump();
      expect(find.text(r'$51,315.52'), findsOneWidget); // unchanged
    });
  });

  group('ValueChartCard', () {
    testWidgets('draws two lines with a legend', (tester) async {
      await tester.pumpWidget(
        host(ValueChartCard(initial: perf(), loader: (_) async => perf())),
      );
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
      expect(find.text('Invested'), findsOneWidget);
      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData, hasLength(2));
      expect(
        chart.data.lineBarsData[1].dashArray,
        isNotNull,
      ); // invested is dashed
      expect(chart.data.lineBarsData[0].barWidth, 2);
      expect(chart.data.minY, 0); // honest baseline
    });

    testWidgets('loads a range once, then serves it from memory', (
      tester,
    ) async {
      final asked = <String>[];
      await tester.pumpWidget(
        host(
          ValueChartCard(
            initial: perf(),
            loader: (range) async {
              asked.add(range);
              return perf(
                range: range,
                series: [
                  {'date': '2026-09-01', 'investedCents': 1, 'valueCents': 1},
                  {'date': '2026-09-10', 'investedCents': 1, 'valueCents': 2},
                ],
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('3M'));
      await tester.pumpAndSettle();
      expect(asked, ['3M']);
      expect(
        tester
            .widget<LineChart>(find.byType(LineChart))
            .data
            .lineBarsData[0]
            .spots,
        hasLength(2),
      );

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3M'));
      await tester.pumpAndSettle();
      expect(asked, ['3M']); // not fetched again
    });

    testWidgets('shows a message instead of a chart with under two points', (
      tester,
    ) async {
      final one = perf(
        series: [
          {'date': '2026-09-01', 'investedCents': 30000, 'valueCents': 30000},
        ],
      );
      await tester.pumpWidget(
        host(ValueChartCard(initial: one, loader: (_) async => one)),
      );
      expect(find.byKey(const Key('chart-empty')), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('a failed range load shows the error and keeps the app alive', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          ValueChartCard(
            initial: perf(),
            loader: (_) async => throw Exception('server down'),
          ),
        ),
      );
      await tester.tap(find.text('1Y'));
      await tester.pumpAndSettle();
      expect(find.textContaining('server down'), findsOneWidget);
    });

    testWidgets('offers the same data as a table', (tester) async {
      await tester.pumpWidget(
        host(ValueChartCard(initial: perf(), loader: (_) async => perf())),
      );
      await tester.tap(find.text('Show data table'));
      await tester.pumpAndSettle();
      expect(find.text(r'$715.00'), findsOneWidget); // latest value row
      expect(find.text('Date'), findsOneWidget);
    });

    testWidgets('renders on the dark theme too', (tester) async {
      await tester.pumpWidget(
        host(
          ValueChartCard(initial: perf(), loader: (_) async => perf()),
          theme: AppTheme.dark,
        ),
      );
      expect(find.byType(LineChart), findsOneWidget);
    });
  });

  group('summary tiles', () {
    testWidgets('include shares and the month streak', (tester) async {
      await tester.pumpWidget(
        host(
          PerformanceCard(
            performance: perf(),
            onRefresh: () {},
            currentStreak: 3,
          ),
        ),
      );
      expect(find.text('5.5000'), findsOneWidget);
      expect(find.text('Month streak'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('omit the streak when it is unknown', (tester) async {
      await tester.pumpWidget(
        host(PerformanceCard(performance: perf(), onRefresh: () {})),
      );
      expect(find.byKey(const Key('streak-figure')), findsNothing);
    });
  });
}
