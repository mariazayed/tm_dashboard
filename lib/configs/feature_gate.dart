import '../constants/route_names.dart';
import '../enums/decision_category_enum.dart';
import '../enums/goal_category_enum.dart';

/// Where the app lands when trading is off, and where hidden trading URLs are sent.
const String investingHomePath = '/invest';

/// Top-level paths that only exist for trading. The home dashboard at `/` is
/// trading-only too, but is handled separately because every other path starts with `/`.
const List<String> tradingPaths = [
  '/calendar',
  '/trading-hours',
  '/trades',
  '/risk-management',
  '/strategies',
  '/assets',
  '/capital',
  '/strict-rules',
];

/// Menu / route names that only exist for trading (includes the trading home).
const Set<String> tradingRouteNames = {
  RouteNames.home,
  RouteNames.calendar,
  RouteNames.tradingHours,
  RouteNames.trades,
  RouteNames.riskManagement,
  RouteNames.strategies,
  RouteNames.assets,
  RouteNames.capital,
  RouteNames.strictRules,
};

bool isTradingRouteName(String? name) =>
    name != null && tradingRouteNames.contains(name);

/// Router redirect: sends the trading home and every trading path to the
/// investing home while trading is off. Returns null to leave the URL alone.
String? tradingRedirect(String path, {required bool tradingEnabled}) {
  if (tradingEnabled) return null;
  final clean = path.length > 1 && path.endsWith('/')
      ? path.substring(0, path.length - 1)
      : path;
  if (clean == '/') return investingHomePath;
  for (final p in tradingPaths) {
    if (clean == p || clean.startsWith('$p/')) return investingHomePath;
  }
  return null;
}

/// Goal categories offered in pickers and filters. Every category except
/// MANUAL is computed from trade data, so only MANUAL is left without trading.
List<GoalCategoryEnum> goalCategoriesFor({required bool tradingEnabled}) =>
    tradingEnabled
    ? GoalCategoryEnum.values
    : const [GoalCategoryEnum.MANUAL];

List<DecisionCategoryEnum> decisionCategoriesFor({
  required bool tradingEnabled,
}) => tradingEnabled
    ? DecisionCategoryEnum.values
    : DecisionCategoryEnum.values
          .where((c) => c != DecisionCategoryEnum.TRADING)
          .toList();
