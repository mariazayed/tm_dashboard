import 'dart:math';
import 'package:flutter/material.dart';

import 'risk_equity_curve_chart.dart';
import 'risk_metrics.dart';
import 'risk_stat.dart';

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

  // Ensure this is ALWAYS initialized (not late without init, not nullable).
  final Map<String, ScrollController> _cardScrollControllers =
  <String, ScrollController>{};

  ScrollController _getCardScrollController(String key) {
    // Avoid calling putIfAbsent on a potentially uninitialized map and keep it simple.
    return _cardScrollControllers[key] ??= ScrollController();
  }

  double v(TextEditingController c) => double.tryParse(c.text) ?? 0;

  List<double> equityCurve = [];

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
                _kpiBar(metrics, metrics.riskOfRuin),
                const SizedBox(height: 24),

                if (isDesktop)
                  _desktopMainLayout()
                else
                  _mobileMainLayout(),

                const SizedBox(height: 24),
                _secondaryStatsGrid(isTablet ? 3 : 1, metrics),
              ],
            ),
          );
        },
      ),
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

  Widget _kpi(String label, double value, String suffix,
      {required String tooltip}) {
    // Determine background color based on KPI
    Color bgColor = Colors.grey.shade100;
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
      case 'Edge':
        if (value > 0.2) valueColor = Colors.green;
        else if (value > 0) valueColor = Colors.orange;
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

  Widget _desktopMainLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 340,
          child: _card('Trading Controls', _inputsSection()),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _card(
            'Equity Curve',
            SizedBox(
              height: 420,
              child: equityCurve.isEmpty
                  ? _emptyState()
                  : RiskEquityCurveChart(equityCurve,      startingCapital: max(v(capitalCtrl), 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _mobileMainLayout() {
    return Column(
      children: [
        _card('Trading Controls', _inputsSection()),
        const SizedBox(height: 24),
        if (equityCurve.isNotEmpty)
          _card(
            'Equity Curve',
            SizedBox(height: 300, child: RiskEquityCurveChart(equityCurve,      startingCapital: max(v(capitalCtrl), 1),
            )),
          ),
      ],
    );
  }
  Widget _secondaryStatsGrid(int columns, RiskMetrics metrics) {
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        _card('Expectancy 🎯', _expectancyStats(metrics)),
        _card('Risk Exposure ⚠️', _riskStats(metrics)),
        _card('Performance 💰', _performanceStats(metrics)),
        _card('Time & Growth ⏳', _timeStats(metrics)),
        _card('Distribution 📊', _distributionStats(metrics)),
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

  Widget _kpiBar(RiskMetrics m, double ruin) {
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
        // _kpi(
        //   'Edge',
        //   m.edgeScore,
        //   '',
        //   tooltip:
        //   'Edge = expectancy / risk per trade.\nGood: >0.2 means you have positive expectancy.\nBad: <0 indicates negative expectancy.',
        // ),
        _kpi(
          'Ruin',
          ruin * 100,
          '%',
          tooltip:
          'Risk of ruin based on your strategy.\nGood: <1% means strategy is sustainable.\nBad: >10% is dangerous.',
        ),
      ],
    );
  }

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
      'Max Drawdown %': RiskStat(m.maxDrawdownPct, m.maxDrawdownPct),
      'Risk % Per Trade': RiskStat(m.riskPct * 100, m.riskPct * 100),
      'Trades': RiskStat(m.trades.toDouble(), 0),
      'Trades / Day': RiskStat(m.tradesPerDay.toDouble(), 0),
    });
  }

  Widget _performanceStats(RiskMetrics m) {
    return _stats({
      'Start Capital \$': RiskStat(m.capital, 0),
      'Final Capital \$': RiskStat(m.finalCapital, 0),
      'Net P/L \$': RiskStat(
        m.finalCapital - m.capital,
        m.totalReturnPct,
      ),
      'Total Return %': RiskStat(m.totalReturnPct, m.totalReturnPct),
    });
  }

  Widget _distributionStats(RiskMetrics m) {
    return _stats({
      'Winning Trades': RiskStat(m.wins.toDouble(),
          (m.wins / m.trades) * 100),
      'Losing Trades': RiskStat(m.losses.toDouble(),
          (m.losses / m.trades) * 100),
    });
  }

  Color _statColor(String label, double value) {
    switch (label) {
      case 'Risk / Trade \$':
      case 'Daily Risk \$':
      case 'Weekly Risk \$':
      case 'Monthly Risk \$':
        if (value < 100) return Colors.green;
        else if (value < 500) return Colors.orange;
        else return Colors.red;

      case 'Reward / Trade \$':
      case 'Daily Reward \$':
      case 'Weekly Reward \$':
      case 'Monthly Reward \$':
      case 'Total Wins \$':
      case 'Net P/L \$':
      case 'Capital Increase %':
        return value >= 0 ? Colors.green : Colors.red;

      case 'Total Losses \$':
      case 'Losing Trades':
        return value < 0 ? Colors.green : Colors.red;

      case 'Winning Trades':
        return value > 0 ? Colors.green : Colors.red;

      default:
        return Colors.black;
    }
  }

  Widget _timeStats(RiskMetrics m) {
    return _stats({
      'Days': RiskStat(m.days, 0, tooltip: 'Estimated trading days to complete all trades.'),
      'Weeks': RiskStat(m.weeks, 0, tooltip: 'Estimated weeks to complete trades.'),
      'Months': RiskStat(m.months, 0, tooltip: 'Estimated months to complete trades.'),
    }, showPercent: false);
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
}

