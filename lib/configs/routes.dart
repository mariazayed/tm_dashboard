import 'package:go_router/go_router.dart';

import '../constants/route_names.dart';
import '../screens/assets/assets_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/capital_management/capital_management_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/memoir/memoir_screen.dart';
import '../screens/reminder_notes/reminder_notes_screen.dart';
import '../screens/risk_management/risk_management_screen.dart';
import '../screens/trade_journal/trade_journal_screen.dart';
import '../widgets/menu_bar.dart';

final GoRouter routes = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainManu(child: child);
      },
      routes: [
        GoRoute(
          name: RouteNames.home,
          path: '/',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              name: RouteNames.calendar,
              path: 'calendar',
              builder: (context, state) => CalendarScreen(),
            ),
            GoRoute(
              name: RouteNames.memoir,
              path: 'memoir',
              builder: (context, state) => MemoirScreen(),
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
              name: RouteNames.assets,
              path: 'assets',
              builder: (context, state) => AssetScreen(),
            ),
            GoRoute(
              name: RouteNames.capitalManagement,
              path: 'capitals-management',
              builder: (context, state) => CapitalManagementScreen(),
            ),
            GoRoute(
              name: RouteNames.reminderNotes,
              path: 'reminder-notes',
              builder: (context, state) => ReminderNotesScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);