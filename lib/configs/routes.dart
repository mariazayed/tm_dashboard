import 'package:go_router/go_router.dart';
import 'package:tm_dashboard/screens/calendar/calendar_screen.dart';
import 'package:tm_dashboard/screens/home/home_screen.dart';
import 'package:tm_dashboard/screens/journal/trade_journal.dart';
import 'package:tm_dashboard/screens/memoir/memoir_screen.dart';

import '../constants/route_names.dart';
import '../screens/risk_management/risk_management_screen.dart';
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
          ],
        ),
      ],
    ),
  ],
);