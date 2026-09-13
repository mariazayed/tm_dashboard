import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../enums/session_enum.dart';
import 'dashboard_bar_row.dart';

const Map<SessionEnum, String> _sessionLabels = {
  SessionEnum.NEW_YORK_SESSION: 'New York',
  SessionEnum.LONDON_SESSION: 'London',
  SessionEnum.ASIAN_SESSION: 'Asian',
};

/// "PnL by Session" card -- net profit/loss per trading session (New
/// York / London / Asian), from `TradeAnalyticsHelper.pnlBySession()`.
///
/// Same green/red-by-sign convention as [StrategyPerformanceChart], for the
/// same reason: the app already has an established profit/loss color
/// language, so a generic diverging pair would be redundant here.
class SessionPerformanceChart extends StatelessWidget {
  final List<MapEntry<SessionEnum, double>> data;
  final bool loading;

  const SessionPerformanceChart({
    super.key,
    required this.data,
    this.loading = false,
  });

  static const _green = Color(0xFF16A34A);
  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    if (loading) return _buildShimmer();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                "No session data yet",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          else
            ..._rows(),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
          child: Icon(
            Icons.schedule,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "PnL by Session",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  List<Widget> _rows() {
    final maxAbs = data
        .map((e) => e.value.abs())
        .fold(0.0, (a, b) => a > b ? a : b);

    return [
      for (final entry in data)
        DashboardBarRow(
          label: _sessionLabels[entry.key] ?? entry.key.name,
          valueText:
              "${entry.value >= 0 ? '+' : ''}${entry.value.toStringAsFixed(2)}",
          fraction: maxAbs == 0 ? 0 : entry.value.abs() / maxAbs,
          color: entry.value >= 0 ? _green : _red,
        ),
    ];
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
      ),
    );
  }
}
