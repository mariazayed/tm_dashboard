import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'classes/trade_journal.dart';

class JournalCard extends StatelessWidget {
  final TradeJournal journal;
  const JournalCard({super.key, required this.journal});

  @override
  Widget build(BuildContext context) {
    final profitColor =
    journal.totalProfit >= 0 ? Colors.green : Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          DateFormat('dd MMM yyyy HH:mm')
              .format(journal.entryDateTime),
        ),
        subtitle: Text(
          'Trades: ${journal.trades.length} • '
              'P/L: ${journal.totalProfit.toStringAsFixed(2)} \$',
          style: TextStyle(color: profitColor),
        ),
        children: journal.trades.map((t) {
          return Column(
            children: [
              ListTile(
                title: Text(
                  '${t.asset.symbol} ${t.direction.name.toUpperCase()}',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entry ${t.entryPrice} → Exit ${t.exitPrice}',
                    ),

                    // 📝 Trade notes
                    if (t.notes != null && t.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        t.notes!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Text(
                  '${t.profit.toStringAsFixed(2)} \$',
                  style: TextStyle(
                    color: t.profit >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),

              // Divider between trades
              if (t != journal.trades.last)
                const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}
