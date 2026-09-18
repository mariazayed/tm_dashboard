import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../enums/mistake_tag_enum.dart';
import '../../theme/app_theme.dart';
import 'dashboard_bar_row.dart';

const Map<MistakeTagEnum, String> _mistakeTagLabels = {
  MistakeTagEnum.MOVED_SL_AGAINST_PLAN: 'Moved SL Against Plan',
  MistakeTagEnum.OVERSIZED_POSITION: 'Oversized Position',
  MistakeTagEnum.REVENGE_TRADE: 'Revenge Trade',
  MistakeTagEnum.FOMO_ENTRY: 'FOMO Entry',
  MistakeTagEnum.NO_CONFIRMATION_WAITED: 'No Confirmation Waited',
  MistakeTagEnum.IGNORED_NEWS_EVENT: 'Ignored News Event',
  MistakeTagEnum.EXITED_TOO_EARLY: 'Exited Too Early',
  MistakeTagEnum.EXITED_TOO_LATE: 'Exited Too Late',
  MistakeTagEnum.OVERTRADING: 'Overtrading',
  MistakeTagEnum.BROKE_STRICT_RULE: 'Broke Strict Rule',
  MistakeTagEnum.CHASED_ENTRY: 'Chased Entry',
  MistakeTagEnum.NO_STOP_LOSS: 'No Stop Loss',
};

/// "Mistake Frequency" card -- how often each mistake tag has been applied
/// across reviewed trades, from `TradeAnalyticsHelper.mistakeTagFrequency()`.
///
/// Ties the Trade Review flow's `mistakeTags` field (previously only
/// visible one trade at a time) into a pattern the user can actually act
/// on, and pairs naturally with the existing Strict Rule card already on
/// this page. This is a single-series magnitude chart (a count, no
/// polarity), so it uses one consistent hue rather than the green/red
/// PnL convention used elsewhere on this page.
class MistakeTagChart extends StatelessWidget {
  final List<MapEntry<MistakeTagEnum, int>> data;
  final bool loading;
  final int maxVisible;

  const MistakeTagChart({
    super.key,
    required this.data,
    this.loading = false,
    this.maxVisible = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return _buildShimmer(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: colorScheme.shadow.withValues(alpha: 0.05),
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
                "No mistake tags recorded yet",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          else
            ..._rows(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final amber = context.semanticColors.warning;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: amber.withValues(alpha: 0.12),
          ),
          child: Icon(Icons.warning_amber, size: 18, color: amber),
        ),
        const SizedBox(width: 10),
        Text(
          "Mistake Frequency",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  List<Widget> _rows(BuildContext context) {
    final amber = context.semanticColors.warning;
    final visible = data.take(maxVisible).toList();
    final maxCount = visible.fold(0, (a, b) => a > b.value ? a : b.value);
    final remaining = data.length - visible.length;

    return [
      for (final entry in visible)
        DashboardBarRow(
          label: _mistakeTagLabels[entry.key] ?? entry.key.name,
          valueText: "${entry.value}",
          fraction: maxCount == 0 ? 0 : entry.value / maxCount,
          color: amber,
        ),
      if (remaining > 0)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            "+$remaining more",
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
    ];
  }

  Widget _buildShimmer(BuildContext context) {
    final semantic = context.semanticColors;

    return Shimmer.fromColors(
      baseColor: semantic.shimmerBase,
      highlightColor: semantic.shimmerHighlight,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}
