import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/route_names.dart';
import '../../models/invest/contribution_status_model.dart';
import '../../models/invest/invest_settings_model.dart';
import '../../models/invest/money.dart';
import '../../models/invest/performance_model.dart';
import '../../services/contribution_service.dart';
import '../auth/auth_cubit.dart';
import 'contribution_status_card.dart';
import 'performance_card.dart';
import 'projection_panel.dart';
import 'value_chart_card.dart';

/// Landing page of the investing tracker: the plan, this month's status and
/// a way into the contribution log.
class InvestHomeScreen extends StatefulWidget {
  const InvestHomeScreen({super.key});

  @override
  State<InvestHomeScreen> createState() => _InvestHomeScreenState();
}

class _InvestHomeScreenState extends State<InvestHomeScreen> {
  late Future<(InvestSettingsModel, ContributionStatusModel, PerformanceModel)>
  _future;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(InvestSettingsModel, ContributionStatusModel, PerformanceModel)>
  _load() async {
    final service = ContributionService.shared;
    try {
      final results = await Future.wait([
        service.getSettings(),
        service.getStatus(),
        service.getPerformance(),
      ]);
      return (
        results[0] as InvestSettingsModel,
        results[1] as ContributionStatusModel,
        results[2] as PerformanceModel,
      );
    } on InvestApiException catch (e) {
      // Token expired or revoked: drop to the login screen.
      if (e.unauthorized) await authCubit.logout();
      rethrow;
    }
  }

  Future<void> _refreshPrices() async {
    setState(() => _refreshing = true);
    String? message;
    try {
      final result = await ContributionService.shared.refreshPrices();
      message = result.ok
          ? 'Prices updated'
          : 'Could not fetch prices (${result.error}). Showing the last saved prices.';
      if (mounted) setState(() => _future = _load());
    } on InvestApiException catch (e) {
      if (e.unauthorized) await authCubit.logout();
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
        final (settings, status, performance) = snapshot.data!;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Invest', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Plan: ${Money.format(settings.monthlyAmountCents, settings.currency)}'
                  ' / month into ${settings.ticker}, on day ${settings.buyDay}.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                PerformanceCard(
                  performance: performance,
                  onRefresh: _refreshPrices,
                  refreshing: _refreshing,
                  currentStreak: status.currentStreak,
                ),
                const SizedBox(height: 16),
                ValueChartCard(
                  key: ValueKey(performance.priceAsOf),
                  initial: performance,
                  loader: (range) =>
                      ContributionService.shared.getPerformance(range: range),
                ),
                const SizedBox(height: 16),
                ContributionStatusCard(status: status),
                const SizedBox(height: 16),
                ProjectionPanel(
                  startCents: performance.valueCents,
                  monthlyCents: settings.monthlyAmountCents,
                  currency: settings.currency,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () =>
                          context.goNamed(RouteNames.investContributions),
                      child: const Text('Contributions'),
                    ),
                    OutlinedButton(
                      onPressed: authCubit.logout,
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
