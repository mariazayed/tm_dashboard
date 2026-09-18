import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/trade_direction_enum.dart';
import '../../models/trade_model.dart';
import '../../theme/app_theme.dart';
import 'classes/trade_journal.dart';

/// One trade bucket (a calendar day/week/month, or a custom N-day interval
/// -- see TradeGrouping in classes/trade_journal.dart) as a collapsible
/// card. Visual language matches TradeRowTile on the flat trade list
/// (lib/screens/trade_list/trade_row_tile.dart) -- same accent-bar + pill
/// styling -- so the combined Trades screen feels like one surface whether
/// grouped or not.
///
/// Formerly JournalCard, rendering a TradeJournal (a group of trades sharing
/// one exact entry/exit timestamp). Trades and Trade Journal were merged
/// into a single screen, and the exact-timestamp grouping was replaced by
/// the daily/weekly/monthly/custom grouping this card now renders -- the
/// stat getters (tradeCount, winRate, isProfit, totalProfit, hasUnreviewed)
/// are unchanged, so only the header's label source changed.
class TradeGroupCard extends StatefulWidget {
  final TradeGroup group;

  const TradeGroupCard({super.key, required this.group});

  @override
  State<TradeGroupCard> createState() => _TradeGroupCardState();
}

class _TradeGroupCardState extends State<TradeGroupCard> {
  static final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  bool _isExpanded = false;
  bool _hovering = false;

  TradeGroup get group => widget.group;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final profitColor = group.isProfit ? semantic.profit : semantic.loss;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovering
                  ? profitColor.withOpacity(0.25)
                  : colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: _hovering ? 24 : 16,
                color: colorScheme.shadow.withValues(alpha: _hovering ? 0.07 : 0.04),
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// HEADER
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Result accent bar.
                      Container(width: 5, color: profitColor),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.event_outlined,
                                          size: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            group.label,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                        if (group.hasUnreviewed) ...[
                                          const SizedBox(width: 8),
                                          Tooltip(
                                            message: 'Has unreviewed trades',
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: semantic.orange.withValues(alpha: 0.12),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.schedule,
                                                size: 11,
                                                color: semantic.orange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        _metaChip(
                                          Icons.receipt_long_rounded,
                                          '${group.tradeCount} trade${group.tradeCount == 1 ? '' : 's'}',
                                        ),
                                        _metaChip(
                                          Icons.emoji_events_outlined,
                                          '${group.winRate.toStringAsFixed(0)}% win',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _profitBadge(group.isProfit, profitColor),
                              const SizedBox(width: 10),
                              _expandButton(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// EXPANDED CONTENT
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                sizeCurve: Curves.easeOut,
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Column(
                    children: [
                      Divider(height: 1, color: colorScheme.outlineVariant),
                      const SizedBox(height: 14),
                      ...group.trades.map(_tradeTile),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profitBadge(bool isProfit, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '${isProfit ? '+' : ''}${_money.format(group.totalProfit)}',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expandButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedRotation(
      turns: _isExpanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _tradeTile(Trade t) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final isProfit = t.profit >= 0;
    final profitColor = isProfit ? semantic.profit : semantic.loss;
    final isLong = t.direction == TradeDirectionEnum.LONG;
    final directionColor = isLong ? semantic.profit : semantic.loss;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  t.asset.symbol,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: directionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLong
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 10,
                      color: directionColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      isLong ? 'LONG' : 'SHORT',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: directionColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!t.isReviewed) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: 'Not reviewed yet',
                  child: Icon(
                    Icons.schedule,
                    size: 13,
                    color: semantic.orange,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${isProfit ? '+' : ''}${_money.format(t.profit)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: profitColor,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
          if (t.strategy != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                t.strategy!.name,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Entry ${t.entryPrice} → Exit ${t.exitPrice}',
            style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
          ),
          if (t.notes != null && t.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              t.notes!,
              style: TextStyle(fontSize: 12.5, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
