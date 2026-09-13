import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/trade_direction_enum.dart';
import '../../models/trade_model.dart';

/// One row in the Trade List. Tapping it opens a detail bottom sheet --
/// same DraggableScrollableSheet pattern the Dashboard screen already uses
/// for capital lists.
class TradeRowTile extends StatelessWidget {
  final Trade trade;

  const TradeRowTile({super.key, required this.trade});

  static final _dateFormat = DateFormat('dd MMM yyyy • HH:mm');

  @override
  Widget build(BuildContext context) {
    final isProfit = trade.profit >= 0;
    final profitColor = isProfit ? Colors.green.shade600 : Colors.red.shade400;
    final isLong = trade.direction == TradeDirectionEnum.LONG;
    final directionColor = isLong ? Colors.green.shade600 : Colors.red.shade400;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetails(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                color: Colors.black.withOpacity(0.04),
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Asset + direction + strategy
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          trade.asset.symbol,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: directionColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            trade.direction.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: directionColor,
                            ),
                          ),
                        ),
                        if (!trade.isReviewed) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.orange.shade600,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateFormat.format(trade.entryDateTime),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (trade.strategy != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        trade.strategy!.name,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Lot / pips
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${trade.lot} lot',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trade.pips.toStringAsFixed(1)} pips',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Profit
              SizedBox(
                width: 90,
                child: Text(
                  '${trade.profit >= 0 ? '+' : ''}${trade.profit.toStringAsFixed(2)} \$',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold, color: profitColor),
                ),
              ),
            ],
          ),
        ),
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
