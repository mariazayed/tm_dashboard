import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/trade_direction_enum.dart';
import '../../models/trade_model.dart';

/// One row in the Trade List. Tapping it opens a detail bottom sheet --
/// same DraggableScrollableSheet pattern the Dashboard screen already uses
/// for capital lists.
class TradeRowTile extends StatefulWidget {
  final Trade trade;

  const TradeRowTile({super.key, required this.trade});

  @override
  State<TradeRowTile> createState() => _TradeRowTileState();
}

class _TradeRowTileState extends State<TradeRowTile> {
  static final _dateFormat = DateFormat('dd MMM yyyy • HH:mm');
  static final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  bool _hovering = false;

  Trade get trade => widget.trade;

  @override
  Widget build(BuildContext context) {
    final isProfit = trade.profit >= 0;
    final profitColor = isProfit ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    final isLong = trade.direction == TradeDirectionEnum.LONG;
    final directionColor = isLong ? const Color(0xFF16A34A) : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openDetails(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              clipBehavior: Clip.antiAlias,
              transform: Matrix4.translationValues(0, _hovering ? -1.5 : 0, 0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _hovering
                      ? profitColor.withOpacity(0.25)
                      : Colors.grey.shade100,
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: _hovering ? 24 : 14,
                    color: Colors.black.withOpacity(_hovering ? 0.07 : 0.04),
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Result accent bar.
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        color: profitColor,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(18),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            _assetAvatar(directionColor),
                            const SizedBox(width: 14),

                            // Asset + direction + strategy
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          trade.asset.symbol,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _directionChip(isLong, directionColor),
                                      if (!trade.isReviewed) ...[
                                        const SizedBox(width: 6),
                                        Tooltip(
                                          message: 'Not reviewed yet',
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.schedule,
                                              size: 11,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.event_outlined,
                                          size: 13, color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      Text(
                                        _dateFormat.format(trade.entryDateTime),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (trade.strategy != null) ...[
                                        const SizedBox(width: 10),
                                        Icon(Icons.label_outline,
                                            size: 13, color: Colors.grey.shade400),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            trade.strategy!.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Lot / pips
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${trade.lot} lot',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${trade.pips >= 0 ? '+' : ''}${trade.pips.toStringAsFixed(1)} pips',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 14),

                            // Profit badge
                            _profitBadge(isProfit, profitColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _assetAvatar(Color color) {
    final symbol = trade.asset.symbol;
    final initials = symbol.length >= 2
        ? symbol.substring(0, 2).toUpperCase()
        : symbol.toUpperCase();

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.16), color.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _directionChip(bool isLong, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLong ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            isLong ? 'LONG' : 'SHORT',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profitBadge(bool isProfit, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${isProfit ? '+' : ''}${_money.format(trade.profit)}',
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

  void _openDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${trade.asset.symbol} • ${trade.direction.name}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '${trade.profit >= 0 ? '+' : ''}${trade.profit.toStringAsFixed(2)} \$',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: trade.profit >= 0
                              ? Colors.green.shade600
                              : Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_dateFormat.format(trade.entryDateTime)}  →  ${_dateFormat.format(trade.exitDateTime)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 32),
                  _detailRow('Entry price', trade.entryPrice.toString()),
                  _detailRow('Exit price', trade.exitPrice.toString()),
                  if (trade.slPrice != null) _detailRow('Stop loss', trade.slPrice.toString()),
                  if (trade.tpPrice != null) _detailRow('Take profit', trade.tpPrice.toString()),
                  _detailRow('Lot size', trade.lot.toString()),
                  _detailRow('Pips', trade.pips.toStringAsFixed(1)),
                  if (trade.strategy != null) _detailRow('Strategy', trade.strategy!.name),
                  _detailRow(
                    'Reviewed',
                    trade.isReviewed
                        ? _dateFormat.format(trade.reviewedAt!)
                        : 'Not reviewed yet',
                  ),
                  if (trade.notes != null && trade.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Notes',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(trade.notes!),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
