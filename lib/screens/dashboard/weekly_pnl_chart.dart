import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_theme.dart';

class WeeklyPnlChart extends StatefulWidget {
  final List<MapEntry<DateTime, double>> weeklyData;
  final bool loading;

  const WeeklyPnlChart({
    super.key,
    required this.weeklyData,
    this.loading = false,
  });

  @override
  State<WeeklyPnlChart> createState() => _WeeklyPnlChartState();
}

class _WeeklyPnlChartState extends State<WeeklyPnlChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyPnlChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyData != widget.weeklyData) {
      _controller.forward(from: 0); // restart animation on data change
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return _buildShimmer(context);
    }

    if (widget.weeklyData.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text("No weekly data")),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final formatter = DateFormat('MMM d');

    final totalPnl = widget.weeklyData.fold(0.0, (sum, e) => sum + e.value);

    final isPositive = totalPnl >= 0;
    final lineColor = isPositive ? semantic.profit : semantic.loss;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          /// 🔥 Animated Counter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Small subtle label
              Text(
                "Total PnL",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 6),

              /// Big animated value
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: totalPnl),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: lineColor,
                          height: 1,
                        ),
                      ),

                      const SizedBox(width: 8),

                      /// Small PnL badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: lineColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          totalPnl >= 0 ? "Profit" : "Loss",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: lineColor,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          /// 🔥 Growing Chart
          SizedBox(
            height: 240,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                final spots = <FlSpot>[];

                for (int i = 0; i < widget.weeklyData.length; i++) {
                  final animatedValue =
                      widget.weeklyData[i].value * _animation.value;

                  spots.add(FlSpot(i.toDouble(), animatedValue));
                }

                return LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (widget.weeklyData.length - 1).toDouble(),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: semantic.chartGridLine.withValues(alpha: 0.5),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 ||
                                index >= widget.weeklyData.length) {
                              return const SizedBox();
                            }

                            final weekStart = widget.weeklyData[index].key;

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                formatter.format(weekStart),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: semantic.chartAxisLabel,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: lineColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              lineColor.withOpacity(0.25),
                              lineColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ✨ Shimmer Loading State
  Widget _buildShimmer(BuildContext context) {
    final semantic = context.semanticColors;

    return Shimmer.fromColors(
      baseColor: semantic.shimmerBase,
      highlightColor: semantic.shimmerHighlight,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}
