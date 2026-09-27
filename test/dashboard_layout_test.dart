import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tm_dashboard/screens/dashboard/dashboard_screen.dart';
import 'package:tm_dashboard/screens/dashboard/capital_growth_chart.dart';
import 'package:tm_dashboard/screens/dashboard/weekly_pnl_chart.dart';
import 'package:tm_dashboard/screens/dashboard/strategy_performance_chart.dart';
import 'package:tm_dashboard/screens/dashboard/session_performance_chart.dart';
import 'package:tm_dashboard/screens/dashboard/expense_summary_chart.dart';
import 'package:tm_dashboard/screens/dashboard/planner_dashboard_section.dart';
import 'package:tm_dashboard/screens/dashboard/weekly_history_table.dart';
import 'package:tm_dashboard/screens/dashboard/dashboard_note_strip.dart';
import 'package:tm_dashboard/theme/app_theme.dart';

void main() {
  for (final width in [390.0, 1280.0]) {
    testWidgets('Dashboard retains charts and navigates at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(theme: AppTheme.light, home: const DashboardScreen()),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          for (final type in [
            CapitalGrowthChart,
            WeeklyPnlChart,
            StrategyPerformanceChart,
            SessionPerformanceChart,
            ExpenseSummaryChart,
            PlannerDashboardSection,
          ]) {
            expect(find.byType(type), findsOneWidget);
          }
          final growth = tester.getTopLeft(find.byType(CapitalGrowthChart));
          final pnl = tester.getTopLeft(find.byType(WeeklyPnlChart));
          expect(
            width > 1100 ? pnl.dy == growth.dy : pnl.dy > growth.dy,
            isTrue,
          );
          expect(
            tester
                .widget<WeeklyHistoryTable>(find.byType(WeeklyHistoryTable))
                .weeks
                .length,
            6,
          );
          final nav = find.widgetWithText(TextButton, 'Trading');
          await tester.tap(nav);
          await tester.pumpAndSettle();
          expect(
            tester.getTopLeft(find.text('Trading performance')).dy,
            inInclusiveRange(100, 160),
          );
          expect(nav.hitTestable(), findsOneWidget);
          await tester.ensureVisible(find.text('View all 8 weeks'));
          await tester.tap(find.text('View all 8 weeks'));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<WeeklyHistoryTable>(find.byType(WeeklyHistoryTable))
                .weeks
                .length,
            8,
          );
          expect(tester.takeException(), isNull);
        },
        () => MockClient((request) async {
          if (request.url.path.endsWith('/overview')) {
            return http.Response(
              jsonEncode({
                'currentWeek': {
                  'weekStart': '2026-09-21',
                  'weekEnd': '2026-09-27',
                  'capacityHours': 40,
                },
                'currentMonth': {'year': 2026, 'month': 9},
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/search')) {
            final data = request.url.path.contains('capital')
                ? List.generate(
                    8,
                    (i) => {
                      'dateTime': DateTime(
                        2026,
                        9,
                        21,
                      ).subtract(Duration(days: i * 7)).toIso8601String(),
                      'amount': 100,
                      'reason': 1,
                    },
                  )
                : [];
            return http.Response(
              jsonEncode({'status': 'success', 'data': data, 'last': true}),
              200,
            );
          }
          return http.Response('[]', 200);
        }),
      );
    });
  }

  testWidgets('Notes stay still until paged and expand for full text', (
    tester,
  ) async {
    var index = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => DashboardNoteStrip(
              title: 'Reminder',
              text: ['First reminder', 'Second reminder'][index],
              icon: Icons.lightbulb_outline,
              accent: Colors.blue,
              loading: false,
              index: index,
              count: 2,
              onNavigate: (delta) =>
                  setState(() => index = (index + delta) % 2),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('First reminder'), findsOneWidget);
    await tester.tap(find.byTooltip('Next Reminder'));
    await tester.pumpAndSettle();
    expect(find.text('Second reminder'), findsOneWidget);
    await tester.tap(find.text('Reminder'));
    await tester.pumpAndSettle();
    expect(find.text('Second reminder'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Previous Reminder'));
    await tester.pumpAndSettle();
    expect(find.text('First reminder'), findsNWidgets(2));
  });
}
