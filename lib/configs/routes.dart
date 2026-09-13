import 'package:go_router/go_router.dart';
import 'package:tm_dashboard/screens/strategies/strategy_screen.dart';
import 'package:tm_dashboard/screens/strict_rules/reminder_notes_screen.dart';

import '../constants/route_names.dart';
import '../screens/assets/assets_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/goals/goals_screen.dart';
import '../screens/reminder_notes/reminder_notes_screen.dart';
import '../screens/risk_management/risk_management_screen.dart';
import '../screens/trade_journal/trade_journal_screen.dart';
import '../screens/trade_list/trade_list_screen.dart';
import '../screens/trade_review/trade_review_screen.dart';
import '../widgets/menu_bar.dart';

final GoRouter routes = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainMenu(child: child);
      },
      routes: [
        GoRoute(
          name: RouteNames.home,
          path: '/',
          builder: (context, state) => DashboardScreen(),
          routes: [
            GoRoute(
              name: RouteNames.calendar,
              path: 'calendar',
              builder: (context, state) => CalendarScreen(),
            ),
            GoRoute(
              name: RouteNames.riskManagement,
              path: 'risk-management',
              builder: (context, state) => RiskManagementScreen(),
            ),
            GoRoute(
              name: RouteNames.tradeJournal,
              path: 'trade-journal',
              builder: (context, state) => TradeJournalScreen(),
            ),
            GoRoute(
              name: RouteNames.tradeList,
              path: 'trades',
              builder: (context, state) => TradeListScreen(),
            ),
            GoRoute(
              name: RouteNames.tradeReview,
              path: 'trade-review',
              builder: (context, state) => TradeReviewScreen(),
            ),
            GoRoute(
              name: RouteNames.goals,
              path: 'goals',
              builder: (context, state) => GoalsScreen(),
            ),
            GoRoute(
              name: RouteNames.assets,
              path: 'assets',
              builder: (context, state) => AssetScreen(),
            ),
            GoRoute(
              name: RouteNames.reminderNotes,
              path: 'reminder-notes',
              builder: (context, state) => ReminderNotesScreen(),
            ),
            GoRoute(
              name: RouteNames.strictRules,
              path: 'strict-rules',
              builder: (context, state) => StrictRulesScreen(),
            ),
            GoRoute(
              name: RouteNames.strategies,
              path: 'strategies',
              builder: (context, state) => StrategiesScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
