import 'package:go_router/go_router.dart';
import 'package:tm_dashboard/screens/strategies/strategy_screen.dart';
import 'package:tm_dashboard/screens/strict_rules/reminder_notes_screen.dart';

import '../constants/route_names.dart';
import '../services/feature_service.dart';
import 'feature_gate.dart';
import '../screens/assets/assets_screen.dart';
import '../screens/invest/ai_chat_screen.dart';
import '../screens/invest/ai_review_screen.dart';
import '../screens/invest/contributions_screen.dart';
import '../screens/invest/insights/insights_screen.dart';
import '../screens/invest/invest_home_screen.dart';
import '../screens/invest/journal_screen.dart';
import '../screens/invest/learning_screen.dart';
import '../screens/invest/rules_screen.dart';
import '../screens/invest/settings_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/capital/capital_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/decisions/decisions_screen.dart';
import '../screens/expense_reasons/expense_reasons_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/goals/goals_screen.dart';
import '../screens/planner/planner_screen.dart';
import '../screens/questions_answers/questions_answers_screen.dart';
import '../screens/reminder_notes/reminder_notes_screen.dart';
import '../screens/risk_management/risk_management_screen.dart';
import '../screens/trade_journal/trade_journal_screen.dart';
import '../screens/trading_hours/trading_hours_screen.dart';
import '../widgets/menu_bar.dart';

final GoRouter routes = GoRouter(
  refreshListenable: Features.notifier,
  redirect: (context, state) => tradingRedirect(
    state.uri.path,
    tradingEnabled: Features.tradingEnabled,
  ),
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
              name: RouteNames.invest,
              path: 'invest',
              builder: (context, state) => const InvestHomeScreen(),
              routes: [
                GoRoute(
                  name: RouteNames.investRules,
                  path: 'rules',
                  builder: (context, state) => const RulesScreen(),
                ),
                GoRoute(
                  name: RouteNames.investSettings,
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                ),
                GoRoute(
                  name: RouteNames.investLearning,
                  path: 'learning',
                  builder: (context, state) => const LearningScreen(),
                ),
                GoRoute(
                  name: RouteNames.investJournal,
                  path: 'journal',
                  builder: (context, state) => const JournalScreen(),
                ),
                GoRoute(
                  name: RouteNames.investAsk,
                  path: 'ask',
                  builder: (context, state) => const AiChatScreen(),
                ),
                GoRoute(
                  name: RouteNames.investReview,
                  path: 'review',
                  builder: (context, state) => const AiReviewScreen(),
                ),
                GoRoute(
                  name: RouteNames.investInsights,
                  path: 'insights',
                  builder: (context, state) => const InsightsScreen(),
                ),
                GoRoute(
                  name: RouteNames.investContributions,
                  path: 'contributions',
                  builder: (context, state) => const ContributionsScreen(),
                ),
              ],
            ),
            GoRoute(
              name: RouteNames.calendar,
              path: 'calendar',
              builder: (context, state) => CalendarScreen(),
            ),
            GoRoute(
              name: RouteNames.tradingHours,
              path: 'trading-hours',
              builder: (context, state) => const TradingHoursScreen(),
            ),
            GoRoute(
              name: RouteNames.riskManagement,
              path: 'risk-management',
              builder: (context, state) => RiskManagementScreen(),
            ),
            GoRoute(
              name: RouteNames.trades,
              path: 'trades',
              builder: (context, state) => TradesScreen(),
            ),
            GoRoute(
              name: RouteNames.goals,
              path: 'goals',
              builder: (context, state) => GoalsScreen(),
            ),
            GoRoute(
              name: RouteNames.planner,
              path: 'planner',
              builder: (context, state) => const PlannerScreen(),
            ),
            GoRoute(
              name: RouteNames.capital,
              path: 'capital',
              builder: (context, state) => CapitalScreen(),
            ),
            GoRoute(
              name: RouteNames.decisions,
              path: 'decisions',
              builder: (context, state) => DecisionsScreen(),
            ),
            GoRoute(
              name: RouteNames.questionsAnswers,
              path: 'questions-answers',
              builder: (context, state) => QuestionsAnswersScreen(),
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
            GoRoute(
              name: RouteNames.expenses,
              path: 'expenses',
              builder: (context, state) => ExpensesScreen(),
            ),
            GoRoute(
              name: RouteNames.expenseReasons,
              path: 'expense-reasons',
              builder: (context, state) => ExpenseReasonsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
