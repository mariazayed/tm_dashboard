import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_theme.dart';

class RiskEquityCurveChart extends StatelessWidget {
  final List<double> equityCurve;
  final double startingCapital;

  const RiskEquityCurveChart(
    this.equityCurve, {
    required this.startingCapital,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (equityCurve.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;

    final minY = equityCurve.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = equityCurve.reduce((a, b) => a > b ? a : b) * 1.05;
    final gradientStops = equityCurve.length == 1
        ? const [0.0]
        : List.generate(
            equityCurve.length,
            (i) => i / (equityCurve.length - 1),
          );

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 50),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (equityCurve.length / 5).ceilToDouble(),
            ),
          ),
        ),
        gridData: FlGridData(show: true, horizontalInterval: (maxY - minY) / 5),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: colorScheme.outline, width: 1),
            bottom: BorderSide(color: colorScheme.outline, width: 1),
            top: const BorderSide(color: Colors.transparent),
            right: const BorderSide(color: Colors.transparent),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              equityCurve.length,
              (index) => FlSpot(index.toDouble(), equityCurve[index]),
            ),
            isCurved: true,
            barWidth: 3,
            dotData: FlDotData(show: false),
            color: colorScheme.onSurface, // main line color
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: equityCurve.map((e) {
                  return e >= startingCapital
                      ? semantic.profit.withValues(alpha: 0.3)
                      : semantic.loss.withValues(alpha: 0.3);
                }).toList(),
                stops: gradientStops,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
