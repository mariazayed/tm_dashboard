import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_theme.dart';
import 'classes/trade_analytics_helper.dart';
import 'trade_stat_tile.dart';

/// "Trade Performance" stat row: win rate, profit factor, avg win, avg
/// loss and current streak -- computed from the actual Trade history
/// (TradeAnalyticsHelper), unlike the rest of the dashboard which is built
/// from the capital ledger.
class TradeStatsRow extends StatelessWidget {
  final TradeAnalyticsHelper analytics;
  final bool loading;
  final VoidCallback? onTap;

  const TradeStatsRow({
    super.key,
    required this.analytics,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return _buildShimmer();

    final semantic = context.semanticColors;
    final neutral = Theme.of(context).colorScheme.onSurfaceVariant;
    final pf = analytics.profitFactor;
    final streak = analytics.currentStreak;

    final tiles = <Widget>[
      TradeStatTile(
        title: "Win Rate",
        icon: Icons.track_changes,
        color: analytics.winRate >= 50 ? semantic.profit : semantic.loss,
        numericValue: analytics.winRate,
        formatter: (v) => "${v.toStringAsFixed(1)}%",
        onTap: onTap,
      ),
      TradeStatTile(
        title: "Profit Factor",
        icon: Icons.balance,
        color: pf == null
            ? neutral
            : (pf >= 1 ? semantic.profit : semantic.loss),
        numericValue: pf ?? 0,
        formatter: (v) => pf == null ? "—" : v.toStringAsFixed(2),
        onTap: onTap,
      ),
      TradeStatTile(
        title: "Avg Win",
        icon: Icons.trending_up,
        color: semantic.profit,
        numericValue: analytics.avgWin,
        formatter: (v) => v.toStringAsFixed(2),
        onTap: onTap,
      ),
      TradeStatTile(
        title: "Avg Loss",
        icon: Icons.trending_down,
        color: semantic.loss,
        numericValue: analytics.avgLoss,
        formatter: (v) => v.toStringAsFixed(2),
        onTap: onTap,
      ),
      TradeStatTile(
        title: "Current Streak",
        icon: Icons.local_fire_department,
        color: streak > 0 ? semantic.profit : (streak < 0 ? semantic.loss : neutral),
        numericValue: streak.toDouble(),
        formatter: (v) {
          final rounded = v.round();
          if (rounded == 0) return "—";
          return rounded > 0 ? "$rounded W" : "${rounded.abs()} L";
        },
        onTap: onTap,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        const spacing = 16.0;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }

  int _columnsFor(double width) {
    if (width > 900) return 5;
    if (width > 560) return 3;
    return 2;
  }

  Widget _buildShimmer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        const spacing = 16.0;
        final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        final semantic = context.semanticColors;

        return Shimmer.fromColors(
          baseColor: semantic.shimmerBase,
          highlightColor: semantic.shimmerHighlight,
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (int i = 0; i < 5; i++)
                Container(
                  width: width,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
