import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RiskManagementScreen extends StatefulWidget {
  const RiskManagementScreen({super.key});

  @override
  State<RiskManagementScreen> createState() =>
      _RiskManagementScreenState();
}

class _RiskManagementScreenState
    extends State<RiskManagementScreen> {
  final capitalCtrl = TextEditingController(text: '10000');
  final riskCtrl = TextEditingController(text: '1');
  final winRateCtrl = TextEditingController(text: '50');
  final rrrCtrl = TextEditingController(text: '2');
  final tradesCtrl = TextEditingController(text: '100');
  final tradesPerDayCtrl = TextEditingController(text: '3');

  List<double> equityCurve = [];

  double v(TextEditingController c) =>
      double.tryParse(c.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    final double capital = max(v(capitalCtrl), 1);
    final riskPct = v(riskCtrl) / 100;
    final winRate = v(winRateCtrl) / 100;
    final double rrr = max(v(rrrCtrl), 1);
    final double trades = v(tradesCtrl);
    final tradesPerDay = max(v(tradesPerDayCtrl), 1);

    /// ───── TRADE DISTRIBUTION ─────
    final winningTrades = trades * winRate;
    final losingTrades = trades - winningTrades;

    /// ───── PER TRADE ─────
    final riskPerTrade = capital * riskPct;
    final rewardPerTrade = riskPerTrade * rrr;

    /// EXPECTANCY & EDGE
    final expectancy =
        (winRate * rewardPerTrade) -
            ((1 - winRate) * riskPerTrade);
    final expectancyPct = expectancy / capital * 100;
    final edgeScore = expectancy / riskPerTrade;

    /// ───── DAILY / WEEKLY / MONTHLY ─────
    final dailyRisk = riskPerTrade * tradesPerDay;
    final dailyReward = rewardPerTrade * tradesPerDay;

    final weeklyRisk = dailyRisk * 5;
    final weeklyReward = dailyReward * 5;

    final monthlyRisk = dailyRisk * 20;
    final monthlyReward = dailyReward * 20;

    /// ───── TOTAL PERFORMANCE ─────
    final totalWins = winningTrades * rewardPerTrade;
    final totalLosses = losingTrades * riskPerTrade;
    final totalAmount = totalWins - totalLosses;

    /// ───── TIME ESTIMATION ─────
    final days = trades / tradesPerDay;
    final weeks = days / 5;
    final months = days / 20;

    /// ───── CAPITAL GROWTH ─────
    final capitalIncreasePct =
        (totalAmount / capital) * 100;

    /// % helper
    double pct(double v) => (v / capital) * 100;

    /// RISK OF RUIN
    final ruin = riskOfRuin(
      winRate: winRate,
      capital: capital,
      riskPerTrade: riskPerTrade,
    );

    /// SIMULATION METRICS
    final double maxDD = equityCurve.isNotEmpty
        ? maxDrawdown(equityCurve)
        : 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Management')),
      body: LayoutBuilder(
        builder: (context, constraints) {
      final width = constraints.maxWidth;

      int columns;
      if (width > 1200) {
        columns = 3;
      } else if (width > 800) {
        columns = 2;
      } else {
        columns = 1;
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _responsiveGrid(
              columns: columns,
              children: [
                _card('Inputs', _inputsSection()),

                _card(
                  'Trade Expectancy 🎯',
                  _stats({
                    'Risk / Trade \$': _Stat(riskPerTrade, pct(riskPerTrade)),
                    'Reward / Trade \$': _Stat(rewardPerTrade, 0),
                    'Expectancy \$': _Stat(expectancy, 0),
                    'Expectancy %': _Stat(expectancyPct, 0),
                    'Edge Score': _Stat(edgeScore, 0),
                    'Risk of Ruin %': _Stat(ruin * 100, 0),
                    'Max Drawdown %': _Stat(maxDD, 0),
                  }),
                ),

                _card(
                  'Trade Distribution',
                  _stats({
                    'Winning Trades':
                    _Stat(winningTrades, winRate * 100),
                    'Losing Trades':
                    _Stat(losingTrades, (1 - winRate) * 100),
                  }),
                ),

                _card(
                  'Risk & Reward Exposure',
                  _stats({
                    'Daily Risk \$': _Stat(dailyRisk, pct(dailyRisk)),
                    'Daily Reward \$': _Stat(dailyReward, pct(dailyReward)),
                    'Weekly Risk \$': _Stat(weeklyRisk, pct(weeklyRisk)),
                    'Weekly Reward \$': _Stat(weeklyReward, pct(weeklyReward)),
                    'Monthly Risk \$': _Stat(monthlyRisk, pct(monthlyRisk)),
                    'Monthly Reward \$': _Stat(monthlyReward, pct(monthlyReward)),
                  }),
                ),

                _card(
                  'Approx. Performance',
                  _stats({
                    'Total Wins \$': _Stat(totalWins, pct(totalWins)),
                    'Total Losses \$': _Stat(totalLosses, pct(totalLosses)),
                    'Net Amount \$': _Stat(totalAmount, pct(totalAmount)),
                  }),
                ),

                _card(
                  'Time & Growth',
                  _stats({
                    'Capital Increase %':
                    _Stat(capitalIncreasePct, capitalIncreasePct),
                    'Days': _Stat(days, 0),
                    'Weeks': _Stat(weeks, 0),
                    'Months': _Stat(months, 0),
                  }, showPercent: false),
                ),
              ],
            ),

            if (equityCurve.isNotEmpty) ...[
              const SizedBox(height: 24),
              _card(
                'Equity Curve 📊',
                SizedBox(
                  height: 350,
                  width: double.infinity,
                  child: EquityCurveChart(equityCurve),
                ),
              ),
            ],
          ],
        ),
      );
    },
    ),
    );
  }

  Widget _responsiveGrid({
    required int columns,
    required List<Widget> children,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.35,
      ),
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }

  Widget _inputsSection() {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _inputSized('Capital', capitalCtrl),
            _inputSized('Risk % / Trade', riskCtrl),
            _inputSized('Win Rate %', winRateCtrl),
            _inputSized('RRR', rrrCtrl),
            _inputSized('Total Trades', tradesCtrl),
            _inputSized('Trades / Day', tradesPerDayCtrl),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run Simulation'),
            onPressed: () {
              setState(() {
                equityCurve = simulateEquityCurve(
                  startingCapital: max(v(capitalCtrl), 1),
                  trades: v(tradesCtrl),
                  winRate: v(winRateCtrl) / 100,
                  riskPct: v(riskCtrl) / 100,
                  rrr: max(v(rrrCtrl), 1),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _inputSized(String l, TextEditingController c) {
    return SizedBox(
      width: 220,
      child: _f(l, c),
    );
  }


  // ───────── UI HELPERS ─────────

  Widget _f(String l, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _stats(
      Map<String, _Stat> data, {
        bool showPercent = true,
      }) {
    return Column(
      children: data.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key),
              Column(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Text(
                    e.value.value.toStringAsFixed(2),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  if (showPercent)
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

  Widget _card(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge),
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

class EquityCurveChart extends StatelessWidget {
  final List<double> curve;
  const EquityCurveChart(this.curve, {super.key});

  @override
  Widget build(BuildContext context) {
    final spots = curve
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: Colors.blueAccent,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

double riskOfRuin({
  required double winRate,
  required double capital,
  required double riskPerTrade,
}) {
  final lossRate = 1 - winRate;
  if (winRate <= 0 || lossRate <= 0) return 1;

  return pow(
    lossRate / winRate,
    capital / riskPerTrade,
  ).toDouble();
}

List<double> simulateEquityCurve({
  required double startingCapital,
  required double trades,
  required double winRate,
  required double riskPct,
  required double rrr,
}) {
  final random = Random();
  double equity = startingCapital;
  final curve = <double>[equity];

  for (int i = 0; i < trades; i++) {
    final risk = equity * riskPct;
    final win = random.nextDouble() <= winRate;
    equity += win ? risk * rrr : -risk;
    curve.add(equity);
  }

  return curve;
}

double maxDrawdown(List<double> curve) {
  double peak = curve.first;
  double maxDD = 0;

  for (final v in curve) {
    if (v > peak) peak = v;
    final dd = (peak - v) / peak;
    maxDD = max(maxDD, dd);
  }

  return maxDD * 100;
}

