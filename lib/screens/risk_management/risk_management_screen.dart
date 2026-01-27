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
  final tradesCtrl = TextEditingController(text: '200');
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
    final trades = v(tradesCtrl).toInt();
    final tradesPerDay = max(v(tradesPerDayCtrl), 1);

    /// CORE RISK
    final riskPerTrade = capital * riskPct;
    final rewardPerTrade = riskPerTrade * rrr;

    /// EXPECTANCY & EDGE
    final expectancy =
        (winRate * rewardPerTrade) -
            ((1 - winRate) * riskPerTrade);
    final expectancyPct = expectancy / capital * 100;
    final edgeScore = expectancy / riskPerTrade;

    /// EXPOSURE
    final dailyRisk = riskPerTrade * tradesPerDay;
    final weeklyRisk = dailyRisk * 5;
    final monthlyRisk = dailyRisk * 20;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              'Inputs',
              Column(
                children: [
                  _f('Capital', capitalCtrl),
                  _f('Risk % / Trade', riskCtrl),
                  _f('Win Rate %', winRateCtrl),
                  _f('RRR', rrrCtrl),
                  _f('Trades', tradesCtrl),
                  _f('Max Trades / Day', tradesPerDayCtrl),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        equityCurve = simulateEquityCurve(
                          startingCapital: capital,
                          trades: trades,
                          winRate: winRate,
                          riskPct: riskPct,
                          rrr: rrr,
                        );
                      });
                    },
                    child: const Text('Run Simulation'),
                  ),
                ],
              ),
            ),

            _card(
              'Trade Expectancy 🎯',
              _stats({
                'Risk / Trade \$': riskPerTrade,
                'Reward / Trade \$': rewardPerTrade,
                'Expectancy \$': expectancy,
                'Expectancy %': expectancyPct,
                'Edge Score': edgeScore,
              }),
            ),

            _card(
              'Exposure & Survival 🚨',
              _stats({
                'Daily Risk \$': dailyRisk,
                'Weekly Risk \$': weeklyRisk,
                'Monthly Risk \$': monthlyRisk,
                'Risk of Ruin %': ruin * 100,
                'Max Drawdown %': maxDD,
              }),
            ),

            if (equityCurve.isNotEmpty)
              _card(
                'Equity Curve 📊',
                SizedBox(
                  height: 280,
                  child: EquityCurveChart(equityCurve),
                ),
              ),
          ],
        ),
      ),
    );
  }

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

  Widget _stats(Map<String, double> data) {
    return Column(
      children: data.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.key),
              Text(
                e.value.toStringAsFixed(2),
                style:
                const TextStyle(fontWeight: FontWeight.bold),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
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
  required int trades,
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

