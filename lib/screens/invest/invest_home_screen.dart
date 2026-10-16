import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/route_names.dart';
import '../../models/invest/contribution_model.dart';
import '../../models/invest/contribution_status_model.dart';
import '../../models/invest/invest_settings_model.dart';
import '../../models/invest/money.dart';
import '../../models/invest/performance_model.dart';
import '../../services/contribution_service.dart';
import '../../services/plan_service.dart';
import '../dashboard/goals_progress_section.dart';
import 'contribution_status_card.dart';
import 'insights/insights_screen.dart';
import 'investing_planner_preview.dart';
import 'performance_card.dart';
import 'recent_contributions_card.dart';
import 'rules_card.dart';

/// Landing page of the investing tracker: the plan, this month's status and
/// a way into the contribution log.
class InvestHomeScreen extends StatefulWidget {
  const InvestHomeScreen({
    super.key,
    ContributionService? contributions,
    PlanService? plan,
  }) : _contributions = contributions,
       _plan = plan;

  // Injectable so the screen can be driven against a fake server in tests.
  final ContributionService? _contributions;
  final PlanService? _plan;

  @override
  State<InvestHomeScreen> createState() => _InvestHomeScreenState();
}

class _InvestHomeScreenState extends State<InvestHomeScreen> {
  ContributionService get _contributions =>
      widget._contributions ?? ContributionService.shared;
  PlanService get _plan => widget._plan ?? PlanService.shared;

  late Future<
    (
      InvestSettingsModel,
      ContributionStatusModel,
      PerformanceModel,
      List<String>,
      List<ContributionModel>,
    )
  >
  _future;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<
    (
      InvestSettingsModel,
      ContributionStatusModel,
      PerformanceModel,
      List<String>,
      List<ContributionModel>,
    )
  >
  _load() async {
    final service = _contributions;
    final results = await Future.wait([
      service.getSettings(),
      service.getStatus(),
      service.getPerformance(),
      // Rules are a nicety here: if they fail to load, the dashboard still shows.
      _plan
          .rules()
          .then<List<String>>((r) => r.map((e) => e.text).toList())
          .catchError((_) => <String>[]),
      service.getAll().catchError((_) => <ContributionModel>[]),
    ]);
    return (
      results[0] as InvestSettingsModel,
      results[1] as ContributionStatusModel,
      results[2] as PerformanceModel,
      results[3] as List<String>,
      results[4] as List<ContributionModel>,
    );
  }

  Future<void> _refreshPrices() async {
    setState(() => _refreshing = true);
    String? message;
    try {
      final result = await _contributions.refreshPrices();
      message = result.ok
          ? 'Prices updated'
          : 'Could not fetch prices (${result.error}). Showing the last saved prices.';
      if (mounted) {
        setState(() {
          _future = _load();
        });
      }
    } on InvestApiException catch (e) {
      message = e.message;
    } catch (_) {
      message = 'Could not reach the server';
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// "Plan: $300 / month into VT, on day 5." or, with several funds, across them.
  String _planLine(InvestSettingsModel settings, PerformanceModel performance) {
    final amount = Money.format(settings.monthlyAmountCents, settings.currency);
    final into = performance.isMixed
        ? 'across ${performance.holdings.length} funds '
              '(${performance.holdings.map((h) => h.ticker).join(', ')})'
        : 'into ${settings.ticker}';
    return 'Plan: $amount / month $into, on day ${settings.buyDay}.';
  }

  Widget _responsivePair({
    required Widget first,
    required Widget second,
    int firstFlex = 1,
    int secondFlex = 1,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 720) {
        return Column(children: [first, const SizedBox(height: 16), second]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: firstFlex, child: first),
          const SizedBox(width: 16),
          Expanded(flex: secondFlex, child: second),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (settings, status, performance, rules, contributions) =
            snapshot.data!;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
            24,
            MediaQuery.sizeOf(context).width < 600 ? 16 : 28,
            32,
          ),
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final action = FilledButton.icon(
                  onPressed: () =>
                      context.goNamed(RouteNames.investContributions),
                  icon: const Icon(Icons.add),
                  label: const Text('Record contribution'),
                );
                final heading = Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Investing Dashboard',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _planLine(settings, performance),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                if (constraints.maxWidth < 580) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [heading, const SizedBox(height: 12), action],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: heading),
                    const SizedBox(width: 16),
                    action,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            PerformanceCard(
              performance: performance,
              cashBalanceCents: contributions.fold<int>(
                0,
                (balance, contribution) =>
                    balance + contribution.cashDeltaCents,
              ),
              onRefresh: _refreshPrices,
              refreshing: _refreshing,
              currentStreak: status.currentStreak,
            ),
            const SizedBox(height: 16),
            ContributionStatusCard(status: status),
            const SizedBox(height: 16),
            _responsivePair(
              first: const GoalsProgressSection(),
              second: const InvestingPlannerPreview(),
            ),
            const SizedBox(height: 16),
            RecentContributionsCard(
              contributions: contributions,
              currency: settings.currency,
              onViewAll: () => context.goNamed(RouteNames.investContributions),
            ),
            const SizedBox(height: 16),
            RulesCard(
              rules: rules,
              onEdit: () => context.goNamed(RouteNames.investRules),
            ),
            const SizedBox(height: 16),
            Text(
              'Analytics',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Explore your portfolio, contribution history and investing habits.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            InsightsScreen(
              key: ValueKey(
                '${performance.priceAsOf}:${contributions.length}:${status.currentStreak}',
              ),
              embedded: true,
              showHeader: false,
              initialSettings: settings,
              initialPerformance: performance,
              initialBuys: contributions,
              initialStatus: status,
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
