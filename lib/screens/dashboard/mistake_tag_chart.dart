import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../enums/mistake_tag_enum.dart';
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

  static const _amber = Color(0xFFF59E0B);

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
                "No mistake tags recorded yet",
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
            color: _amber.withOpacity(0.12),
          ),
          child: const Icon(Icons.warning_amber, size: 18, color: _amber),
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

  List<Widget> _rows() {
    final visible = data.take(maxVisible).toList();
    final maxCount = visible.fold(0, (a, b) => a > b.value ? a : b.value);
    final remaining = data.length - visible.length;

    return [
      for (final entry in visible)
        DashboardBarRow(
          label: _mistakeTagLabels[entry.key] ?? entry.key.name,
          valueText: "${entry.value}",
          fraction: maxCount == 0 ? 0 : entry.value / maxCount,
          color: _amber,
        ),
      if (remaining > 0)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            "+$remaining more",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
    ];
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
        ),
      ),
    );
  }
}
