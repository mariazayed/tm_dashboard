import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/invest/money.dart';
import '../../models/invest/performance_model.dart';
import '../../theme/app_semantic_colors.dart';

typedef PerformanceLoader = Future<PerformanceModel> Function(String range);

/// Invested (dashed, neutral) against value (solid, accent) over time, with a
/// 3M / 1Y / All toggle, a legend, a hover/touch tooltip and a data table.
class ValueChartCard extends StatefulWidget {
  const ValueChartCard({
    super.key,
    required this.initial,
    required this.loader,
  });

  /// The "ALL" range, already loaded by the page.
  final PerformanceModel initial;
  final PerformanceLoader loader;

  static const ranges = ['3M', '1Y', 'ALL'];

  /// Validated against the app's light and dark card surfaces (>= 3:1).
  static const valueLight = Color(0xFF2A78D6);
  static const valueDark = Color(0xFF3987E5);

  @override
  State<ValueChartCard> createState() => _ValueChartCardState();
}

class _ValueChartCardState extends State<ValueChartCard> {
  late final Map<String, PerformanceModel> _cache = {'ALL': widget.initial};
  String _range = 'ALL';
  bool _loading = false;
  String? _error;

  Future<void> _select(String range) async {
    if (range == _range) return;
    if (_cache.containsKey(range)) {
      setState(() {
        _range = range;
        _error = null;
      });
      return;
    }
    setState(() {
      _range = range;
      _loading = true;
      _error = null;
    });
    try {
      final loaded = await widget.loader(range);
      if (!mounted) return;
      setState(() {
        _cache[range] = loaded;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final valueColor = dark
        ? ValueChartCard.valueDark
        : ValueChartCard.valueLight;
    final investedColor = context.semanticColors.chartAxisLabel;
    final data = _cache[_range];
    final points = data?.series ?? const <SeriesPoint>[];
    final currency = widget.initial.currency;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Text('Invested vs value', style: theme.textTheme.titleMedium),
                SegmentedButton<String>(
                  key: const Key('range-toggle'),
                  showSelectedIcon: false,
                  segments: [
                    for (final r in ValueChartCard.ranges)
                      ButtonSegment(
                        value: r,
                        label: Text(r == 'ALL' ? 'All' : r),
                      ),
                  ],
                  selected: {_range},
                  onSelectionChanged: (s) => _select(s.first),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Legend(valueColor: valueColor, investedColor: investedColor),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: _body(
                context,
                points,
                currency,
                valueColor,
                investedColor,
              ),
            ),
            if (points.length >= 2)
              _DataTable(points: points, currency: currency),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    List<SeriesPoint> points,
    String currency,
    Color valueColor,
    Color investedColor,
  ) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (points.length < 2) {
      return const Center(
        key: Key('chart-empty'),
        child: Text(
          'The chart appears once there are two or more days of data.\n'
          'Add contributions and refresh prices.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return _Chart(
      points: points,
      currency: currency,
      valueColor: valueColor,
      investedColor: investedColor,
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.valueColor, required this.investedColor});

  final Color valueColor;
  final Color investedColor;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: 16,
      children: [
        _Swatch(color: valueColor, dashed: false, label: 'Value', style: style),
        _Swatch(
          color: investedColor,
          dashed: true,
          label: 'Invested',
          style: style,
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.dashed,
    required this.label,
    required this.style,
  });

  final Color color;
  final bool dashed;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Solid vs dashed, so the two lines never rely on colour alone.
        SizedBox(
          width: 22,
          height: 2,
          child: dashed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    3,
                    (_) => Container(width: 5, height: 2, color: color),
                  ),
                )
              : ColoredBox(color: color),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.points,
    required this.currency,
    required this.valueColor,
    required this.investedColor,
  });

  final List<SeriesPoint> points;
  final String currency;
  final Color valueColor;
  final Color investedColor;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final theme = Theme.of(context);
    final first = points.first.date;
    double x(SeriesPoint p) => p.date.difference(first).inDays.toDouble();
    final byX = {for (final p in points) x(p): p};
    final span = x(points.last);
    final maxCents = points
        .map(
          (p) =>
              p.valueCents > p.investedCents ? p.valueCents : p.investedCents,
        )
        .reduce((a, b) => a > b ? a : b);
    final maxY = (maxCents / 100) * 1.1;
    final labelStyle = TextStyle(color: semantic.chartAxisLabel, fontSize: 11);
    final compact = NumberFormat.compactSimpleCurrency(name: currency);
    final dateFormat = span > 400 ? DateFormat.yMMM() : DateFormat.MMMd();

    LineChartBarData line(
      double Function(SeriesPoint) y,
      Color color, {
      bool dashed = false,
    }) => LineChartBarData(
      spots: [for (final p in points) FlSpot(x(p), y(p))],
      color: color,
      barWidth: 2,
      isCurved: false,
      dotData: const FlDotData(show: false),
      dashArray: dashed ? [6, 4] : null,
    );

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: span == 0 ? 1 : span,
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: semantic.chartGridLine.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min && value != 0) {
                  return const SizedBox.shrink();
                }
                return Text(compact.format(value), style: labelStyle);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: span <= 4 ? 1 : span / 4,
              getTitlesWidget: (value, meta) {
                if (value == meta.max && value != meta.min) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dateFormat.format(first.add(Duration(days: value.round()))),
                    style: labelStyle,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          line((p) => p.valueCents / 100, valueColor),
          line((p) => p.investedCents / 100, investedColor, dashed: true),
        ],
        lineTouchData: LineTouchData(
          touchSpotThreshold: 24,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => semantic.tooltipBackground,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (spots) => [
              for (final s in spots)
                if (s.barIndex != 0)
                  null
                else
                  LineTooltipItem(
                    '${DateFormat.yMMMd().format(byX[s.x]!.date)}\n',
                    TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.left,
                    children: [
                      TextSpan(
                        text:
                            'Value ${Money.format(byX[s.x]!.valueCents, currency)}\n',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text:
                            'Invested ${Money.format(byX[s.x]!.investedCents, currency)}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same data as the chart, as a table, for screen readers and exact values.
class _DataTable extends StatelessWidget {
  const _DataTable({required this.points, required this.currency});

  final List<SeriesPoint> points;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    final headerStyle = Theme.of(context).textTheme.bodySmall;
    // Newest first, capped: the table is a reference, not the full history.
    final rows = points.reversed.take(60).toList();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: const Key('data-table'),
        tilePadding: EdgeInsets.zero,
        title: const Text('Show data table'),
        children: [
          Row(
            children: [
              Expanded(child: Text('Date', style: headerStyle)),
              Expanded(
                child: Text(
                  'Invested',
                  style: headerStyle,
                  textAlign: TextAlign.end,
                ),
              ),
              Expanded(
                child: Text(
                  'Value',
                  style: headerStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 220,
            child: ListView(
              children: [
                for (final p in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(fmt.format(p.date))),
                        Expanded(
                          child: Text(
                            Money.format(p.investedCents, currency),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            Money.format(p.valueCents, currency),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
