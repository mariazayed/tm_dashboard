import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'classes/trade_journal.dart';

class JournalCard extends StatefulWidget {
  final TradeJournal journal;

  const JournalCard({super.key, required this.journal});

  @override
  State<JournalCard> createState() => _JournalCardState();
}

class _JournalCardState extends State<JournalCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final journal = widget.journal;
    final isProfit = journal.totalProfit >= 0;

    final profitColor = isProfit ? Colors.green : Colors.red;
    final profitBg = isProfit
        ? Colors.green.withOpacity(0.08)
        : Colors.red.withOpacity(0.08);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          /// HEADER
          GestureDetector(
            onTap: () => setState(() => isExpanded = !isExpanded),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat(
                          'dd MMM yyyy • HH:mm',
                        ).format(journal.entryDateTime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${journal.trades.length} trades',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                /// Profit badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: profitBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${journal.totalProfit.toStringAsFixed(2)} \$',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: profitColor,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// Expand button (NEW)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => isExpanded = !isExpanded),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// EXPANDED CONTENT
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(),
            secondChild: Column(
              children: [
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                ...journal.trades.map((t) {
                  final tradeProfitColor = t.profit >= 0
                      ? Colors.green
                      : Colors.red;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// TOP ROW
                        Row(
                          children: [
                            Text(
                              t.asset.symbol,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),

                            /// Direction Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: t.direction.name == 'LONG'
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t.direction.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: t.direction.name == 'LONG'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),

                            const Spacer(),

                            Text(
                              '${t.profit.toStringAsFixed(2)} \$',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tradeProfitColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        /// STRATEGY BADGE (NEW)
                        if (t.strategy != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              t.strategy!.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                          ),

                        /// Entry / Exit
                        Text(
                          'Entry ${t.entryPrice} → Exit ${t.exitPrice}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),

                        /// Notes
                        if (t.notes != null && t.notes!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            t.notes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
