import 'dart:math';
import 'package:flutter/material.dart';

import 'risk_equity_curve_chart.dart';
import 'risk_metrics.dart';
import 'risk_stat.dart';

class RiskManagementScreen extends StatefulWidget {
  const RiskManagementScreen({super.key});

  @override
  State<RiskManagementScreen> createState() => _RiskManagementScreenState();
}

class _RiskManagementScreenState extends State<RiskManagementScreen> {
  final capitalCtrl = TextEditingController(text: '1000');
  final riskCtrl = TextEditingController(text: '4');
  final winRateCtrl = TextEditingController(text: '50');
  final rrrCtrl = TextEditingController(text: '2');
  final tradesCtrl = TextEditingController(text: '20');
  final tradesPerDayCtrl = TextEditingController(text: '2');

  final Map<String, ScrollController> _cardScrollControllers = {};

  ScrollController _getCardScrollController(String key) {
    return _cardScrollControllers[key] ??= ScrollController();
  }

  double v(TextEditingController c) => double.tryParse(c.text) ?? 0;

  // Monte-Carlo / simulation outputs
  List<double> equityCurve = [];
  double finalCapital = 0;
  double maxDrawdownPct = 0;
  int wins = 0;
  int losses = 0;

  @override
  void dispose() {
    for (final controller in _cardScrollControllers.values) {
      controller.dispose();
    }
    _cardScrollControllers.clear();

    capitalCtrl.dispose();
    riskCtrl.dispose();
    winRateCtrl.dispose();
    rrrCtrl.dispose();
    tradesCtrl.dispose();
    tradesPerDayCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theoretical metrics
    final metrics = RiskMetrics(
      capital: max(v(capitalCtrl), 1),
      riskPct: v(riskCtrl) / 100,
      winRate: v(winRateCtrl) / 100,
      rrr: max(v(rrrCtrl), 1),
      trades: v(tradesCtrl).toInt(),
      tradesPerDay: max(v(tradesPerDayCtrl).toInt(), 1),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Management')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 1200;
          final isTablet = constraints.maxWidth > 800;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kpiBar(metrics),
                const SizedBox(height: 24),
                if (isDesktop)
                  _desktopMainLayout(metrics)
                else
                  _mobileMainLayout(metrics),
                const SizedBox(height: 24),
                _secondaryStatsGrid(isTablet ? 3 : 1, metrics),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- INPUTS ----------------

  Widget _inputsSection(RiskMetrics metrics) {
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
                  trades: v(tradesCtrl).toInt(),
                  winRate: v(winRateCtrl) / 100,
                  riskPct: v(riskCtrl) / 100,
                  rrr: max(v(rrrCtrl), 1),
                );

                // Compute derived metrics from curve
                finalCapital = equityCurve.last;
                maxDrawdownPct = _maxDrawdown(equityCurve);
                final results = _countWinsLosses(equityCurve);
                wins = results.$1;
                losses = results.$2;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _inputSized(String l, TextEditingController c) {
    return SizedBox(width: 220, child: _f(l, c));
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

  // ---------------- STATS & CARDS ----------------

  Widget _card(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final header = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
              ],
            );

            if (constraints.hasBoundedHeight) {
              final controller = _getCardScrollController(title);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  Expanded(
                    child: Scrollbar(
                      controller: controller,
                      thumbVisibility: false,
                      child: SingleChildScrollView(
                        controller: controller,
                        child: child,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                child,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stats(Map<String, RiskStat> data, {bool showPercent = true}) {
    return Column(
      children: data.entries.map((e) {
        final stat = e.value;
        final valueColor = _statColor(e.key, stat.value);

        final child = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(e.key),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stat.value.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: valueColor),
                ),
                if (showPercent)
                  Text(
                    '${stat.percent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ],
        );

        if (stat.tooltip != null) {
          return Tooltip(
            message: stat.tooltip!,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(color: Colors.white),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: child,
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: child,
          );
        }
      }).toList(),
    );
  }

  // ---------------- KPI BAR ----------------

  Widget _kpiBar(RiskMetrics m) {
    return Row(
      children: [
        _kpi(
          'Capital',
          m.capital,
          '\$',
          tooltip:
          'Your starting capital.\nGood: higher capital allows more flexibility.\nBad: low capital increases risk per trade impact.',
        ),
        _kpi(
          'Risk / Trade',
          m.riskPct * 100,
          '%',
          tooltip:
          'Percentage of capital risked per trade.\nGood: 0.5%-2% keeps drawdown low.\nBad: >5% is very risky.',
        ),
        _kpi(
          'Win Rate',
          m.winRate * 100,
          '%',
          tooltip:
          'Percentage of trades that are winners.\nGood: >50% consistently.\nBad: <40% indicates low strategy efficiency.',
        ),
        _kpi(
          'Ruin',
          m.riskOfRuin * 100,
          '%',
          tooltip:
          'Risk of ruin based on your strategy.\nGood: <1% means strategy is sustainable.\nBad: >10% is dangerous.',
        ),
      ],
    );
  }

  Widget _kpi(String label, double value, String suffix,
      {required String tooltip}) {
    Color valueColor = Colors.black;

    switch (label) {
      case 'Capital':
        valueColor = value >= 10000 ? Colors.green : Colors.orange;
        break;
      case 'Risk / Trade':
        if (value < 2) valueColor = Colors.green;
        else if (value < 5) valueColor = Colors.orange;
        else valueColor = Colors.red;
        break;
      case 'Win Rate':
        if (value > 55) valueColor = Colors.green;
        else if (value > 45) valueColor = Colors.orange;
        else valueColor = Colors.red;
        break;
      case 'Ruin':
        if (value < 1) valueColor = Colors.green;
        else if (value < 5) valueColor = Colors.orange;
        else valueColor = Colors.red;
        break;
    }

    return Expanded(
      child: Tooltip(
        message: tooltip,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  '${value.toStringAsFixed(2)}$suffix',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- MAIN LAYOUTS ----------------

  Widget _desktopMainLayout(RiskMetrics metrics) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 340,
          child: _card('Trading Controls', _inputsSection(metrics)),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _card(
            'Equity Curve',
            SizedBox(
              height: 420,
              child: equityCurve.isEmpty
                  ? _emptyState()
                  : RiskEquityCurveChart(
                equityCurve,
                startingCapital: max(v(capitalCtrl), 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileMainLayout(RiskMetrics metrics) {
    return Column(
      children: [
        _card('Trading Controls', _inputsSection(metrics)),
        const SizedBox(height: 24),
        if (equityCurve.isNotEmpty)
          _card(
            'Equity Curve',
            SizedBox(
              height: 300,
              child: RiskEquityCurveChart(
                equityCurve,
                startingCapital: max(v(capitalCtrl), 1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _secondaryStatsGrid(int columns, RiskMetrics m) {
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        _card('Expectancy 🎯', _expectancyStats(m)),
        _card('Risk Exposure ⚠️', _riskStats(m)),
        _card('Performance 💰', _performanceStats(m)),
        _card('Time & Growth ⏳', _timeStats(m)),
        _card('Distribution 📊', _distributionStats()),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Run simulation to generate equity curve',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ---------------- STATS CALCULATIONS ----------------

  Widget _expectancyStats(RiskMetrics m) {
    return _stats({
      'Average Risk / Trade \$': RiskStat(m.averageRPerTrade, m.averageRPerTrade,
          tooltip: 'Amount risked per trade. Good: 0.5%-2% of capital. High risk is dangerous.'),
      'Average Reward / Trade \$': RiskStat(m.avgRewardPerTrade, m.avgRewardPerTrade,
          tooltip: 'Expected reward per trade based on your RRR.'),
      'Expectancy \$': RiskStat(m.expectancyR, m.expectancyR,
          tooltip: 'Average expected gain per trade. Positive is good.'),
      'Expectancy %': RiskStat(m.expectancyR, m.expectancyR,
          tooltip: 'Expectancy as % of capital. Higher is better.'),
    });
  }

  Widget _riskStats(RiskMetrics m) {
    return _stats({
      'Max Drawdown %': RiskStat(maxDrawdownPct, maxDrawdownPct),
      'Risk % Per Trade': RiskStat(m.riskPct * 100, m.riskPct * 100),
      'Trades': RiskStat(m.trades.toDouble(), 0),
      'Trades / Day': RiskStat(m.tradesPerDay.toDouble(), 0),
    });
  }

  Widget _performanceStats(RiskMetrics m) {
    return _stats({
      'Start Capital \$': RiskStat(m.capital, 0),
      'Final Capital \$': RiskStat(finalCapital, 0),
      'Net P/L \$': RiskStat(finalCapital - m.capital, (finalCapital - m.capital) / m.capital * 100),
      'Total Return %': RiskStat((finalCapital - m.capital) / m.capital * 100,
          (finalCapital - m.capital) / m.capital * 100),
    });
  }

  Widget _distributionStats() {
    return _stats({
      'Winning Trades': RiskStat(wins.toDouble(), wins / (wins + losses) * 100),
      'Losing Trades': RiskStat(losses.toDouble(), losses / (wins + losses) * 100),
    });
  }

  Widget _timeStats(RiskMetrics m) {
    return _stats({
      'Days': RiskStat(m.days, 0, tooltip: 'Estimated trading days to complete all trades.'),
      'Weeks': RiskStat(m.weeks, 0, tooltip: 'Estimated weeks to complete trades.'),
      'Months': RiskStat(m.months, 0, tooltip: 'Estimated months to complete trades.'),
    }, showPercent: false);
  }

  Color _statColor(String label, double value) {
    switch (label) {
      case 'Risk / Trade \$':
        if (value < 100) return Colors.green;
        else if (value < 500) return Colors.orange;
        else return Colors.red;

      case 'Reward / Trade \$':
      case 'Net P/L \$':
        return value >= 0 ? Colors.green : Colors.red;

      default:
        return Colors.black;
    }
  }

  // ---------------- MONTE-CARLO SIMULATION ----------------

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

  double _maxDrawdown(List<double> curve) {
    double peak = curve.first;
    double maxDD = 0;

    for (final v in curve) {
      if (v > peak) peak = v;
      final dd = (peak - v) / peak;
      maxDD = max(maxDD, dd);
    }

    return maxDD * 100;
  }

  (int, int) _countWinsLosses(List<double> curve) {
    int w = 0;
    int l = 0;

    for (int i = 1; i < curve.length; i++) {
      if (curve[i] > curve[i - 1]) {
        w++;
      } else {
        l++;
      }
    }

    return (w, l);
  }
}