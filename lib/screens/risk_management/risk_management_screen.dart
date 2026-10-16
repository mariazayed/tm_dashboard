import 'dart:math';
import 'package:flutter/material.dart';

import 'package:tm_dashboard/widgets/page_back_button.dart';

import '../../theme/app_theme.dart';
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

  double _capitalInput() => max(v(capitalCtrl), 1);
  double _riskPctInput() => (v(riskCtrl) / 100).clamp(0, 1).toDouble();
  double _winRateInput() => (v(winRateCtrl) / 100).clamp(0, 1).toDouble();
  double _rrrInput() => max(v(rrrCtrl), 0);
  int _tradesInput() => max(v(tradesCtrl).toInt(), 0);
  int _tradesPerDayInput() => max(v(tradesPerDayCtrl).toInt(), 1);

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
      capital: _capitalInput(),
      riskPct: _riskPctInput(),
      winRate: _winRateInput(),
      rrr: _rrrInput(),
      trades: _tradesInput(),
      tradesPerDay: _tradesPerDayInput(),
    );

    return Scaffold(
      appBar: AppBar(
        leading: const PageBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Risk Management'),
      ),
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
                  startingCapital: _capitalInput(),
                  trades: _tradesInput(),
                  winRate: _winRateInput(),
                  riskPct: _riskPctInput(),
                  rrr: _rrrInput(),
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
          fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              children: [header, child],
            );
          },
        ),
      ),
    );
  }

  Widget _stats(Map<String, RiskStat> data, {bool showPercent = true}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: data.entries.map((e) {
        final stat = e.value;
        final valueColor = _statColor(e.key, stat.value);

        final child = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(e.key)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  stat.value.toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
                if (showPercent)
                  Text(
                    '${stat.percent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
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
              color: colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: TextStyle(color: colorScheme.onInverseSurface),
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
              'Starting capital from the Capital input, with a minimum value of 1.',
        ),
        _kpi(
          'Risk / Trade',
          m.riskPct * 100,
          '%',
          tooltip:
              'Risk % input clamped from 0% to 100%. Each simulated trade risks current equity x this percentage.',
        ),
        _kpi(
          'Win Rate',
          m.winRate * 100,
          '%',
          tooltip:
              'Win Rate input clamped from 0% to 100%. The simulation uses this as the probability of a winning trade.',
        ),
        _kpi(
          'Ruin',
          m.riskOfRuin * 100,
          '%',
          tooltip:
              'Approximation: exp((-2 x expectancy R / variance) / risk %), shown as a percentage. Zero risk returns 0%.',
        ),
      ],
    );
  }

  Widget _kpi(
    String label,
    double value,
    String suffix, {
    required String tooltip,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;

    Color valueColor = colorScheme.onSurface;

    switch (label) {
      case 'Capital':
        valueColor = value >= 10000 ? semantic.profit : semantic.orange;
        break;
      case 'Risk / Trade':
        if (value < 2) {
          valueColor = semantic.profit;
        } else if (value < 5) {
          valueColor = semantic.orange;
        } else {
          valueColor = semantic.loss;
        }
        break;
      case 'Win Rate':
        if (value > 55) {
          valueColor = semantic.profit;
        } else if (value > 45) {
          valueColor = semantic.orange;
        } else {
          valueColor = semantic.loss;
        }
        break;
      case 'Ruin':
        if (value < 1) {
          valueColor = semantic.profit;
        } else if (value < 5) {
          valueColor = semantic.orange;
        } else {
          valueColor = semantic.loss;
        }
        break;
    }

    return Expanded(
      child: Tooltip(
        message: tooltip,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: colorScheme.onInverseSurface),
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
                Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
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
                      startingCapital: _capitalInput(),
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
                startingCapital: _capitalInput(),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Run simulation to generate equity curve',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ---------------- STATS CALCULATIONS ----------------

  Widget _expectancyStats(RiskMetrics m) {
    final expectancyDollars = m.avgRiskPerTrade * m.expectancyR;
    return _stats({
      'Average Risk / Trade \$': RiskStat(
        m.avgRiskPerTrade,
        m.riskPct * 100,
        tooltip:
            'Capital x risk %. ${m.capital.toStringAsFixed(2)} x ${(m.riskPct * 100).toStringAsFixed(2)}%.',
      ),
      'Reward / Winning Trade \$': RiskStat(
        m.avgRewardPerTrade,
        m.riskPct * m.rrr * 100,
        tooltip:
            'Risk dollars x RRR. ${m.avgRiskPerTrade.toStringAsFixed(2)} x ${m.rrr.toStringAsFixed(2)}R.',
      ),
      'Expectancy R': RiskStat(
        m.expectancyR,
        m.expectancyR * 100,
        tooltip:
            '(Win rate x RRR) - loss rate. (${(m.winRate * 100).toStringAsFixed(2)}% x ${m.rrr.toStringAsFixed(2)}R) - ${((1 - m.winRate) * 100).toStringAsFixed(2)}%.',
      ),
      'Expectancy \$': RiskStat(
        expectancyDollars,
        expectancyDollars / m.capital * 100,
        tooltip:
            'Expectancy R x risk dollars. ${m.expectancyR.toStringAsFixed(2)}R x ${m.avgRiskPerTrade.toStringAsFixed(2)}.',
      ),
      'Expectancy %': RiskStat(
        m.avgTradeReturnPct,
        m.avgTradeReturnPct,
        tooltip:
            'Expectancy dollars / capital x 100, equivalent to expectancy R x risk %.',
      ),
    });
  }

  Widget _riskStats(RiskMetrics m) {
    return _stats({
      'Max Drawdown %': RiskStat(
        maxDrawdownPct,
        maxDrawdownPct,
        tooltip: 'Worst peak-to-valley drop in the simulated equity curve.',
      ),
      'Risk % Per Trade': RiskStat(
        m.riskPct * 100,
        m.riskPct * 100,
        tooltip:
            'Clamped input risk percentage, used as equity x risk % on each simulated trade.',
      ),
      'Trades': RiskStat(
        m.trades.toDouble(),
        0,
        tooltip: 'Total simulated trades. Negative input is treated as 0.',
      ),
      'Trades / Day': RiskStat(
        m.tradesPerDay.toDouble(),
        0,
        tooltip:
            'Trades divided into trading days. Values below 1 are treated as 1.',
      ),
    });
  }

  Widget _performanceStats(RiskMetrics m) {
    final simulatedFinalCapital = equityCurve.isEmpty
        ? m.capital
        : finalCapital;
    final netPnl = simulatedFinalCapital - m.capital;
    final totalReturnPct = netPnl / m.capital * 100;
    return _stats({
      'Start Capital \$': RiskStat(
        m.capital,
        0,
        tooltip: 'Starting capital after enforcing a minimum of 1.',
      ),
      'Final Capital \$': RiskStat(
        simulatedFinalCapital,
        totalReturnPct,
        tooltip: equityCurve.isEmpty
            ? 'No simulation has run yet, so this equals starting capital.'
            : 'Last value in the simulated equity curve after all trades.',
      ),
      'Net P/L \$': RiskStat(
        netPnl,
        totalReturnPct,
        tooltip: 'Final capital - starting capital.',
      ),
      'Total Return %': RiskStat(
        totalReturnPct,
        totalReturnPct,
        tooltip: 'Net P/L divided by starting capital x 100.',
      ),
    });
  }

  Widget _distributionStats() {
    final total = wins + losses;
    final winPct = total == 0 ? 0.0 : wins / total * 100;
    final lossPct = total == 0 ? 0.0 : losses / total * 100;
    return _stats({
      'Winning Trades': RiskStat(
        wins.toDouble(),
        winPct,
        tooltip:
            'Count of simulated trades where equity increased. Percentage is wins / simulated trades x 100.',
      ),
      'Losing Trades': RiskStat(
        losses.toDouble(),
        lossPct,
        tooltip:
            'Count of simulated trades where equity decreased or stayed flat. Percentage is losses / simulated trades x 100.',
      ),
    });
  }

  Widget _timeStats(RiskMetrics m) {
    return _stats({
      'Days': RiskStat(m.days, 0, tooltip: 'Trades / trades per day.'),
      'Weeks': RiskStat(m.weeks, 0, tooltip: 'Days / 5 trading days.'),
      'Months': RiskStat(m.months, 0, tooltip: 'Days / 20 trading days.'),
    }, showPercent: false);
  }

  Color _statColor(String label, double value) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;

    switch (label) {
      case 'Average Risk / Trade \$':
        if (value < 100) return semantic.profit;
        if (value < 500) return semantic.orange;
        return semantic.loss;

      case 'Reward / Winning Trade \$':
      case 'Net P/L \$':
      case 'Expectancy R':
      case 'Expectancy \$':
      case 'Expectancy %':
        return value >= 0 ? semantic.profit : semantic.loss;

      default:
        return colorScheme.onSurface;
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
