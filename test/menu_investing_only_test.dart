import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tm_dashboard/models/feature_flags.dart';
import 'package:tm_dashboard/services/feature_service.dart';
import 'package:tm_dashboard/theme/theme_cubit.dart';
import 'package:tm_dashboard/widgets/menu_bar.dart';

/// Every route name the menu can link to. The menu resolves each one with
/// `namedLocation`, which throws for an unregistered name, so the stub
/// router has to know all of them.
const _names = [
  'home',
  'calendar',
  'tradingHours',
  'riskManagement',
  'trades',
  'assets',
  'reminderNotes',
  'strictRules',
  'strategies',
  'goals',
  'capital',
  'decisions',
  'questionsAnswers',
  'expenses',
  'expenseReasons',
  'planner',
  'invest',
  'investContributions',
  'investInsights',
  'investJournal',
  'investLearning',
  'investRules',
  'investSettings',
  'investAsk',
  'investReview',
];

Widget _app() {
  final router = GoRouter(
    initialLocation: '/invest',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainMenu(child: child),
        routes: [
          for (final n in _names)
            GoRoute(
              name: n,
              path: n == 'home' ? '/' : '/${n == 'invest' ? 'invest' : n}',
              builder: (_, _) => const SizedBox(),
            ),
        ],
      ),
    ],
  );
  return BlocProvider(
    create: (_) => ThemeCubit(),
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(Features.reset);
  tearDown(Features.reset);

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The test font is much wider than the real one, so long labels overflow
    // the 260px sidebar here; that is a test artefact, not what users see.
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
  }

  testWidgets('trading off: trading entries are gone, investing pages listed', (
    tester,
  ) async {
    await pump(tester);

    for (final hidden in [
      'Home',
      'Calendar',
      'Trading Hours',
      'Trades',
      'Assets',
      'Risk Management',
      'Strategies',
      'Deposits & Withdraws',
      'Strict Rules',
      'Expenses',
      'Expense Reasons',
    ]) {
      expect(find.text(hidden), findsNothing, reason: hidden);
    }
    for (final shown in [
      'Overview',
      'Contributions',
      'Journal',
      'Charts',
      'Goals',
      'Planner',
      'Learning',
      'Rules',
      'Review',
      'Ask your journal',
      'Decisions',
      'Questions & Answers',
      'Reminder Notes',
      'Settings',
    ]) {
      expect(find.text(shown), findsOneWidget, reason: shown);
    }
    expect(find.text('Invest'), findsNothing);
    expect(find.text('Others'), findsNothing);
  });

  testWidgets('trading on: the original menu is unchanged', (tester) async {
    Features.reset(const FeatureFlags(trading: true));
    await pump(tester);

    for (final shown in [
      'Home',
      'Invest',
      'Calendar',
      'Trading Hours',
      'Trades',
    ]) {
      expect(find.text(shown), findsOneWidget, reason: shown);
    }
    expect(find.text('Overview'), findsNothing);
  });
}
