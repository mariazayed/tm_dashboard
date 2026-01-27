import 'package:flutter/material.dart';
import 'dart:math';

class RiskManagementScreen extends StatefulWidget {
  const RiskManagementScreen({super.key});

  @override
  State<RiskManagementScreen> createState() => _RiskManagementScreenState();
}

class _RiskManagementScreenState extends State<RiskManagementScreen> {
  final _winRateCtrl = TextEditingController(text: '65');
  final _tradesCtrl = TextEditingController(text: '20');
  final _riskCtrl = TextEditingController(text: '1.5');
  final _capitalCtrl = TextEditingController(text: '800');
  final _rrrCtrl = TextEditingController(text: '2');
  final _tradesPerDayCtrl = TextEditingController(text: '2');

  double _get(TextEditingController c) =>
      double.tryParse(c.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final winRate = _get(_winRateCtrl) / 100;
    final trades = _get(_tradesCtrl);
    final riskPct = _get(_riskCtrl) / 100;
    final capital = max(_get(_capitalCtrl), 1);
    final rrr = max(_get(_rrrCtrl), 1);
    final tradesPerDay = max(_get(_tradesPerDayCtrl), 1);

    final wins = trades * winRate;
    final losses = trades - wins;

    final riskPerTrade = capital * riskPct;
    final rewardPerTrade = riskPerTrade * rrr;

    final dailyRisk = riskPerTrade * tradesPerDay;
    final dailyReward = rewardPerTrade * tradesPerDay;

    final weeklyRisk = dailyRisk * 5;
    final weeklyReward = dailyReward * 5;

    final monthlyRisk = dailyRisk * 20;
    final monthlyReward = dailyReward * 20;

    final totalWins = wins * rewardPerTrade;
    final totalLosses = losses * riskPerTrade;
    final totalAmount = totalWins - totalLosses;

    double pct(double v) => (v / capital) * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _card(
            title: 'Inputs',
            child: Column(
              children: [
                _row('Win Rate %', _winRateCtrl),
                _row('Number of Trades', _tradesCtrl),
                _row('Risk %', _riskCtrl),
                _row('Capital', _capitalCtrl),
                _row('Min RRR', _rrrCtrl),
                _row('Max Trades / Day', _tradesPerDayCtrl),
              ],
            ),
          ),

          _card(
            title: 'Trade Distribution',
            child: _stats({
              'Winning Trades':
              _Stat(wins, wins / trades * 100),
              'Losing Trades':
              _Stat(losses, losses / trades * 100),
            }, isCount: true),
          ),

          _card(
            title: 'Risk & Reward Exposure',
            child: _stats({
              'Daily Risk \$':
              _Stat(dailyRisk, pct(dailyRisk)),
              'Daily Reward \$':
              _Stat(dailyReward, pct(dailyReward)),
              'Weekly Risk \$':
              _Stat(weeklyRisk, pct(weeklyRisk)),
              'Weekly Reward \$':
              _Stat(weeklyReward, pct(weeklyReward)),
              'Monthly Risk \$':
              _Stat(monthlyRisk, pct(monthlyRisk)),
              'Monthly Reward \$':
              _Stat(monthlyReward, pct(monthlyReward)),
            }),
          ),

          _card(
            title: 'Approx. Performance',
            child: _stats({
              'Total Wins \$':
              _Stat(totalWins, pct(totalWins)),
              'Total Losses \$':
              _Stat(totalLosses, pct(totalLosses)),
              'Net Amount \$':
              _Stat(totalAmount, pct(totalAmount)),
            }),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _stats(Map<String, _Stat> data, {bool isCount = false}) {
    return Column(
      children: data.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    e.value.value.toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${e.value.percent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Stat {
  final double value;
  final double percent;

  _Stat(this.value, this.percent);
}
