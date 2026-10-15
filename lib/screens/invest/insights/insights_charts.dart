import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/invest/contribution_status_model.dart';
import '../../../models/invest/insights_model.dart';
import '../../../models/invest/learning_model.dart';
import '../../../models/invest/performance_model.dart';
import 'insights_data.dart';
import 'insights_kit.dart';

String _shortMonth(String key) =>
    DateFormat("MMM ''yy").format(monthStart(key));

double _days(DateTime d, DateTime from) => d.difference(from).inDays.toDouble();

NumberFormat _compact(String currency) =>
    NumberFormat.compactSimpleCurrency(name: currency);

NumberFormat _full(String currency) =>
    NumberFormat.simpleCurrency(name: currency);

/// Maximum of [values] with a floor, so an all-zero chart still has a scale.
double _top(Iterable<double> values, {double floor = 1}) {
  var m = floor;
  for (final v in values) {
    if (v > m) m = v;
  }
  return m;
}

// ------------------------------------------------------------ contributions

/// What each month's buy was, with planned months that got no buy drawn as
/// an outline of the amount that was due.
class ContributionsByMonthChart extends StatelessWidget {
  const ContributionsByMonthChart({
    super.key,
    required this.months,
    required this.currency,
  });

  final List<MonthPlan> months;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    if (months.isEmpty) {
      return const InsightEmpty('Bars appear after the first planned month.');
    }
    final top =
        _top(
          months.map(
            (m) => m.plannedCents > m.actualCents
                ? m.plannedCents / 100
                : m.actualCents / 100,
          ),
        ) *
        1.15;
    final money = _full(currency);
    return BarChart(
      BarChartData(
        maxY: top,
        minY: 0,
        gridData: gridData(c),
        borderData: FlBorderData(show: false),
        titlesData: titles(
          leftTitles(c, _compact(currency).format),
          indexTitles(c, months.length, (i) => _shortMonth(months[i].month)),
        ),
        barTouchData: barTouch(c, (g, _) {
          final m = months[g];
          final what = m.actualCents > 0
              ? money.format(m.actualCents / 100)
              : 'no buy (${money.format(m.plannedCents / 100)} planned)';
          return '${_shortMonth(m.month)}\n$what';
        }),
        barGroups: [
          for (var i = 0; i < months.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                if (months[i].actualCents > 0)
                  BarChartRodData(
                    toY: months[i].actualCents / 100,
                    color: c.accent,
                    width: 10,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  )
                else
                  BarChartRodData(
                    toY: months[i].plannedCents / 100,
                    color: Colors.transparent,
                    width: 10,
                    borderSide: BorderSide(color: c.bad, width: 1.5),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Planned against actual per month: bars above zero were more than planned,
/// below zero less.
class PlannedVsActualChart extends StatelessWidget {
  const PlannedVsActualChart({
    super.key,
    required this.months,
    required this.currency,
  });

  final List<MonthPlan> months;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    if (months.isEmpty) {
      return const InsightEmpty('Appears after the first planned month.');
    }
    final values = [for (final m in months) m.differenceCents / 100];
    return _SignedBars(
      colors: c,
      values: values,
      labels: [for (final m in months) _shortMonth(m.month)],
      axisFormat: _compact(currency).format,
      tooltip: (i) =>
          '${_shortMonth(months[i].month)}\n${_signed(values[i], _full(currency))} against the plan',
      positive: c.accent,
      negative: c.bad,
    );
  }
}

/// Days from the planned buy day to the day each buy really happened.
class BuyTimingChart extends StatelessWidget {
  const BuyTimingChart({super.key, required this.timing});

  final List<BuyTiming> timing;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    if (timing.isEmpty) {
      return const InsightEmpty('Appears after the first buy.');
    }
    final df = DateFormat.yMMMd();
    return _SignedBars(
      colors: c,
      values: [for (final t in timing) t.daysAfter.toDouble()],
      labels: [for (final t in timing) _shortMonth(monthKey(t.date))],
      axisFormat: (v) => v.toStringAsFixed(0),
      tooltip: (i) {
        final d = timing[i].daysAfter;
        final when = d == 0
            ? 'on the planned day'
            : d > 0
            ? '$d days late'
            : '${-d} days early';
        return '${df.format(timing[i].date)}\n$when';
      },
      positive: c.second,
      negative: c.accent,
    );
  }
}

String _signed(double v, NumberFormat f) =>
    '${v < 0 ? '−' : '+'}${f.format(v.abs())}';

class _SignedBars extends StatelessWidget {
  const _SignedBars({
    required this.colors,
    required this.values,
    required this.labels,
    required this.axisFormat,
    required this.tooltip,
    required this.positive,
    required this.negative,
  });

  final ChartColors colors;
  final List<double> values;
  final List<String> labels;
  final String Function(double) axisFormat;
  final String Function(int) tooltip;
  final Color positive;
  final Color negative;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final maxV = _top(values);
    final minV = values.fold<double>(0, (a, b) => b < a ? b : a);
    return BarChart(
      BarChartData(
        maxY: maxV * 1.15,
        minY: minV * 1.15,
        gridData: gridData(c),
        borderData: FlBorderData(show: false),
        titlesData: titles(
          leftTitles(c, axisFormat),
          indexTitles(c, values.length, (i) => labels[i]),
        ),
        barTouchData: barTouch(c, (g, _) => tooltip(g)),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: values[i] >= 0 ? positive : negative,
                  width: 8,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(values[i] >= 0 ? 3 : 0),
                    bottom: Radius.circular(values[i] < 0 ? 3 : 0),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- price

/// The price per share over time. With [showAvgCost] it also draws your
/// average cost, so you can see when the position was in profit. With [buys]
/// it marks each buy on the price line.
class PriceLineChart extends StatelessWidget {
  const PriceLineChart({
    super.key,
    required this.points,
    required this.currency,
    this.showAvgCost = false,
    this.buys = const [],
  });

  final List<PricePoint> points;
  final String currency;
  final bool showAvgCost;
  final List<({DateTime date, double price})> buys;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    if (points.length < 2) {
      return const InsightEmpty(
        'Appears once there are two or more days of data.\nAdd contributions and refresh prices.',
      );
    }
    final first = points.first.date;
    final span = _days(points.last.date, first);
    final all = [
      ...points.map((p) => p.price),
      if (showAvgCost) ...points.map((p) => p.avgCost),
      ...buys.map((b) => b.price),
    ];
    final lo = all.reduce((a, b) => a < b ? a : b);
    final hi = all.reduce((a, b) => a > b ? a : b);
    final pad = (hi - lo) * 0.12 + 0.5;
    final money = _full(currency);
    final df = span > 400 ? DateFormat.yMMM() : DateFormat.MMMd();

    LineChartBarData line(
      double Function(PricePoint) y,
      Color color, {
      bool dashed = false,
    }) => LineChartBarData(
      spots: [for (final p in points) FlSpot(_days(p.date, first), y(p))],
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
        minY: (lo - pad).floorToDouble().clamp(0, double.infinity),
        maxY: hi + pad,
        gridData: gridData(c),
        borderData: FlBorderData(show: false),
        titlesData: titles(
          leftTitles(c, (v) => v.toStringAsFixed(0)),
          SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: span <= 4 ? 1 : span / 4,
            getTitlesWidget: (value, meta) {
              if (value == meta.max && value != meta.min) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  df.format(first.add(Duration(days: value.round()))),
                  style: labelStyle(c),
                ),
              );
            },
          ),
        ),
        lineBarsData: [
          line((p) => p.price, showAvgCost ? c.muted : c.accent),
          if (showAvgCost) line((p) => p.avgCost, c.accent, dashed: true),
          if (buys.isNotEmpty)
            LineChartBarData(
              spots: [
                for (final b in buys)
                  FlSpot(_days(b.date, first).clamp(0, span), b.price),
              ],
              barWidth: 0,
              color: Colors.transparent,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 3.5,
                      color: c.second,
                      strokeWidth: 1,
                      strokeColor: c.tooltipBg,
                    ),
              ),
            ),
        ],
        lineTouchData: lineTouch(c, (spots) {
          final s = spots.first;
          final date = df.format(first.add(Duration(days: s.x.round())));
          if (s.barIndex == (showAvgCost ? 2 : 1) && buys.isNotEmpty) {
            return '$date\nBought at ${money.format(s.y)}';
          }
          if (showAvgCost) {
            PricePoint? p;
            for (final q in points) {
              if (_days(q.date, first) == s.x) p = q;
            }
            return p == null
                ? date
                : '$date\nPrice ${money.format(p.price)}\nAverage cost ${money.format(p.avgCost)}';
          }
          return '$date\nPrice ${money.format(s.y)}';
        }),
      ),
    );
  }
}

// ------------------------------------------------------------ running totals

/// A total that steps up at each date: fees paid, shares owned.
class StepTotalChart extends StatelessWidget {
  const StepTotalChart({
    super.key,
    required this.values,
    required this.axisFormat,
    required this.tooltipFormat,
    required this.color,
  });

  final List<DatedValue> values;
  final String Function(double) axisFormat;
  final String Function(double) tooltipFormat;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    if (values.isEmpty) {
      return const InsightEmpty('Appears after the first buy.');
    }
    final first = values.first.date;
    // Extend the last step to the end so a single buy still draws a line.
    final last = values.last;
    final span = _days(last.date, first);
    final spots = [
      for (final v in values) FlSpot(_days(v.date, first), v.value),
    ];
    final df = span > 400 ? DateFormat.yMMM() : DateFormat.MMMd();
    final top = _top(values.map((v) => v.value), floor: 0.5) * 1.15;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: span == 0 ? 1 : span,
        minY: 0,
        maxY: top,
        gridData: gridData(c),
        borderData: FlBorderData(show: false),
        titlesData: titles(
          leftTitles(c, axisFormat),
          SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: span <= 4 ? 1 : span / 4,
            getTitlesWidget: (value, meta) {
              if (value == meta.max && value != meta.min) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  df.format(first.add(Duration(days: value.round()))),
                  style: labelStyle(c),
                ),
              );
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: color,
            barWidth: 2,
            isCurved: false,
            isStepLineChart: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
        lineTouchData: lineTouch(c, (spots) {
          final s = spots.first;
          return '${df.format(first.add(Duration(days: s.x.round())))}\n${tooltipFormat(s.y)}';
        }),
      ),
    );
  }
}

// ----------------------------------------------------------- plan changes

/// Value over time with a vertical line wherever the plan changed.
class ValueWithChangesChart extends StatelessWidget {
  const ValueWithChangesChart({
    super.key,
    required this.series,
    required this.marks,
    required this.currency,
  });

  final List<SeriesPoint> series;
  final List<PlanChangeMark> marks;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    if (series.length < 2) {
      return const InsightEmpty(
        'Appears once there are two or more days of data.',
      );
    }
    final first = series.first.date;
    final span = _days(series.last.date, first);
    final top = _top(series.map((p) => p.valueCents / 100)) * 1.12;
    final df = span > 400 ? DateFormat.yMMM() : DateFormat.MMMd();
    final inRange = [
      for (final m in marks)
        if (!m.date.isBefore(first) && !m.date.isAfter(series.last.date)) m,
    ];
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: span == 0 ? 1 : span,
        minY: 0,
        maxY: top,
        gridData: gridData(c),
        borderData: FlBorderData(show: false),
        titlesData: titles(
          leftTitles(c, _compact(currency).format),
          SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: span <= 4 ? 1 : span / 4,
            getTitlesWidget: (value, meta) {
              if (value == meta.max && value != meta.min) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  df.format(first.add(Duration(days: value.round()))),
                  style: labelStyle(c),
                ),
              );
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          verticalLines: [
            for (final m in inRange)
              VerticalLine(
                x: _days(m.date, first),
                color: c.second,
                strokeWidth: 1.5,
                dashArray: [4, 4],
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final p in series)
                FlSpot(_days(p.date, first), p.valueCents / 100),
            ],
            color: c.accent,
            barWidth: 2,
            isCurved: false,
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: lineTouch(c, (spots) {
          final s = spots.first;
          final date = first.add(Duration(days: s.x.round()));
          return '${DateFormat.yMMMd().format(date)}\n${_full(currency).format(s.y)}';
        }),
      ),
    );
  }
}

// ------------------------------------------------------ stacked month bars

class StackSeries {
  const StackSeries(this.label, this.color, this.values);

  final String label;
  final Color color;

  /// One value per month, in the same order as the months.
  final List<int> values;
}

/// Counts per month stacked by kind.
class StackedMonthChart extends StatelessWidget {
  const StackedMonthChart({
    super.key,
    required this.months,
    required this.series,
  });

  final List<String> months;
  final List<StackSeries> series;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    final totals = [
      for (var i = 0; i < months.length; i++)
        series.fold<int>(0, (a, s) => a + s.values[i]),
    ];
    if (totals.every((t) => t == 0)) {
      return const InsightEmpty('Nothing recorded in these months.');
    }
    final top = _top(totals.map((t) => t.toDouble()), floor: 2) * 1.2;
    return BarChart(
      BarChartData(
        maxY: top,
        minY: 0,
        gridData: gridData(c),
        borderData: FlBorderData(show: false),
        titlesData: titles(
          SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value != value.roundToDouble()) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(value.toStringAsFixed(0), style: labelStyle(c)),
              );
            },
          ),
          indexTitles(
            c,
            months.length,
            (i) => _shortMonth(months[i]),
            target: 6,
          ),
        ),
        barTouchData: barTouch(c, (g, _) {
          final lines = [
            for (final s in series)
              if (s.values[g] > 0) '${s.label}: ${s.values[g]}',
          ];
          return '${_shortMonth(months[g])}\n${lines.isEmpty ? 'None' : lines.join('\n')}';
        }),
        barGroups: [
          for (var i = 0; i < months.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: totals[i].toDouble(),
                  width: 14,
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                  rodStackItems: _stack(i),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<BarChartRodStackItem> _stack(int i) {
    final items = <BarChartRodStackItem>[];
    var from = 0.0;
    for (final s in series) {
      final v = s.values[i].toDouble();
      if (v <= 0) continue;
      items.add(BarChartRodStackItem(from, from + v, s.color));
      from += v;
    }
    return items;
  }
}

// ----------------------------------------------------------------- cards due

/// Flashcards coming due over the next two weeks.
class CardsDueChart extends StatelessWidget {
  const CardsDueChart({super.key, required this.due, required this.today});

  final CardsDue due;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    if (due.perDay.every((n) => n == 0)) {
      return InsightEmpty(
        due.later > 0
            ? 'Nothing due in the next two weeks.'
            : 'No flashcards yet.',
      );
    }
    final top = _top(due.perDay.map((n) => n.toDouble()), floor: 2) * 1.2;
    final df = DateFormat.MMMd();
    String dayLabel(int i) =>
        i == 0 ? 'Today' : df.format(today.add(Duration(days: i)));
    return BarChart(
      BarChartData(
        maxY: top,
        minY: 0,
        gridData: gridData(c),
        borderData: FlBorderData(show: false),
        titlesData: titles(
          SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value != value.roundToDouble()) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(value.toStringAsFixed(0), style: labelStyle(c)),
              );
            },
          ),
          indexTitles(c, due.perDay.length, dayLabel, target: 4),
        ),
        barTouchData: barTouch(
          c,
          (g, _) =>
              '${g == 0 ? 'Today and overdue' : dayLabel(g)}\n${due.perDay[g]} ${due.perDay[g] == 1 ? 'card' : 'cards'}',
        ),
        barGroups: [
          for (var i = 0; i < due.perDay.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: due.perDay[i].toDouble(),
                  color: i == 0 ? c.second : c.accent,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- reading list

/// One bar split by reading-list status.
class ReadingProgressBar extends StatelessWidget {
  const ReadingProgressBar({super.key, required this.counts});

  final Map<SourceStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return const InsightEmpty('Add something to your reading list.');
    }
    final colors = {
      SourceStatus.todo: c.muted,
      SourceStatus.inProgress: c.second,
      SourceStatus.done: c.accent,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 22,
            child: Row(
              children: [
                for (final s in SourceStatus.values)
                  if ((counts[s] ?? 0) > 0)
                    Expanded(
                      flex: counts[s]!,
                      child: Container(
                        margin: const EdgeInsets.only(right: 2),
                        color: colors[s],
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            for (final s in SourceStatus.values)
              Text(
                '${s.label}: ${counts[s] ?? 0}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- returns

/// How the monthly price changes were spread, in bins of two points.
class ReturnsHistogram extends StatelessWidget {
  const ReturnsHistogram({super.key, required this.returns});

  final List<MonthlyReturn> returns;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    if (returns.length < 3) {
      return const InsightEmpty(
        'Appears once there are a few months of prices.',
      );
    }
    final bins = histogram([for (final r in returns) r.monthly], 0.02);
    final top = _top(bins.map((b) => b.count.toDouble()), floor: 2) * 1.2;
    final pct = NumberFormat.decimalPercentPattern(decimalDigits: 0);
    return BarChart(
      BarChartData(
        maxY: top,
        minY: 0,
        gridData: gridData(c),
        borderData: FlBorderData(show: false),
        titlesData: titles(
          SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value != value.roundToDouble()) {
                return const SizedBox.shrink();
              }
              return SideTitleWidget(
                meta: meta,
                child: Text(value.toStringAsFixed(0), style: labelStyle(c)),
              );
            },
          ),
          indexTitles(
            c,
            bins.length,
            (i) => pct.format(bins[i].from),
            target: 6,
          ),
        ),
        barTouchData: barTouch(c, (g, _) {
          final b = bins[g];
          return '${pct.format(b.from)} to ${pct.format(b.from + 0.02)}\n${b.count} ${b.count == 1 ? 'month' : 'months'}';
        }),
        barGroups: [
          for (var i = 0; i < bins.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: bins[i].count.toDouble(),
                  color: bins[i].from < 0 ? c.bad : c.accent,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The price change over the previous 12 months, month by month.
class Rolling12Chart extends StatelessWidget {
  const Rolling12Chart({super.key, required this.returns});

  final List<MonthlyReturn> returns;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    final rows = [
      for (final r in returns)
        if (r.rolling12 != null) r,
    ];
    if (rows.length < 2) {
      return const InsightEmpty('Needs 13 months of prices.');
    }
    final values = [for (final r in rows) r.rolling12! * 100];
    final lo = values.fold<double>(0, (a, b) => b < a ? b : a);
    final hi = values.fold<double>(0, (a, b) => b > a ? b : a);
    final pad = (hi - lo) * 0.15 + 1;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (rows.length - 1).toDouble(),
        minY: lo - pad,
        maxY: hi + pad,
        gridData: gridData(c),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 0,
              color: c.muted,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ],
        ),
        titlesData: titles(
          leftTitles(c, (v) => '${v.toStringAsFixed(0)}%'),
          indexTitles(
            c,
            rows.length,
            (i) => _shortMonth(rows[i].month),
            target: 5,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            color: c.accent,
            barWidth: 2,
            isCurved: false,
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: lineTouch(c, (spots) {
          final i = spots.first.x.round().clamp(0, rows.length - 1);
          return '${_shortMonth(rows[i].month)}\n${NumberFormat('+0.0%;−0.0%').format(rows[i].rolling12)} over 12 months';
        }),
      ),
    );
  }
}

// ----------------------------------------------------------------- AI usage

/// Model calls per day against the daily cap.
class AiUsageChart extends StatelessWidget {
  const AiUsageChart({super.key, required this.history});

  final AiUsageHistoryModel history;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    final days = history.days;
    if (days.isEmpty) return const InsightEmpty('No usage recorded.');
    final top =
        _top([
          ...days.map((d) => d.calls.toDouble()),
          history.dailyLimit.toDouble(),
        ]) *
        1.2;
    final df = DateFormat.MMMd();
    return BarChart(
      BarChartData(
        maxY: top,
        minY: 0,
        gridData: gridData(c),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: history.dailyLimit.toDouble(),
              color: c.bad,
              strokeWidth: 1.5,
              dashArray: [5, 4],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(color: c.label, fontSize: 11),
                labelResolver: (_) => 'Daily limit ${history.dailyLimit}',
              ),
            ),
          ],
        ),
        titlesData: titles(
          leftTitles(c, (v) => v.toStringAsFixed(0), reserved: 36),
          indexTitles(
            c,
            days.length,
            (i) => df.format(days[i].date),
            target: 5,
          ),
        ),
        barTouchData: barTouch(
          c,
          (g, _) =>
              '${df.format(days[g].date)}\n${days[g].calls} ${days[g].calls == 1 ? 'call' : 'calls'}',
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].calls.toDouble(),
                  color: days[i].calls >= history.dailyLimit ? c.bad : c.accent,
                  width: 6,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- grids

/// One cell of a month grid.
class MonthCell {
  const MonthCell({
    required this.month,
    required this.fill,
    required this.glyph,
    required this.tooltip,
    this.outline,
  });

  final String month;
  final Color fill;
  final String glyph;
  final String tooltip;
  final Color? outline;
}

/// Months in rows by year, one small cell per month. Shape and a glyph carry
/// the state as well as colour.
class MonthGrid extends StatelessWidget {
  const MonthGrid({super.key, required this.cells, this.cellHeight = 30});

  final List<MonthCell> cells;
  final double cellHeight;

  @override
  Widget build(BuildContext context) {
    final c = ChartColors.of(context);
    final theme = Theme.of(context);
    if (cells.isEmpty) {
      return const InsightEmpty('Appears after the first planned month.');
    }
    final years = <int, Map<int, MonthCell>>{};
    for (final cell in cells) {
      final d = monthStart(cell.month);
      (years[d.year] ??= {})[d.month] = cell;
    }
    final style = theme.textTheme.bodySmall?.copyWith(color: c.label);
    const names = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 40),
            for (final n in names)
              Expanded(
                child: Center(child: Text(n, style: style)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (final y in years.keys.toList()..sort())
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('$y', style: style)),
                for (var m = 1; m <= 12; m++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: _cell(years[y]![m], c),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(MonthCell? cell, ChartColors c) {
    if (cell == null) {
      return Container(
        height: cellHeight,
        decoration: BoxDecoration(
          color: c.grid.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    return Tooltip(
      message: cell.tooltip,
      child: Semantics(
        label: cell.tooltip,
        child: Container(
          height: cellHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cell.fill,
            borderRadius: BorderRadius.circular(4),
            border: cell.outline == null
                ? null
                : Border.all(color: cell.outline!, width: 1.5),
          ),
          child: Text(
            cell.glyph,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cell.fill == Colors.transparent ? c.label : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Builds the plan grid cells from the contribution status.
List<MonthCell> planCells(
  ContributionStatusModel status,
  ChartColors c,
  NumberFormat money,
) => [
  for (final m in status.months)
    switch (m.state) {
      MonthState.done => MonthCell(
        month: m.month,
        fill: c.accent,
        glyph: m.contributions > 1 ? '${m.contributions}' : '✓',
        tooltip:
            '${_shortMonth(m.month)}: bought ${money.format(m.totalCents / 100)}',
      ),
      MonthState.missed => MonthCell(
        month: m.month,
        fill: c.bad,
        glyph: '×',
        tooltip: '${_shortMonth(m.month)}: missed',
      ),
      MonthState.overdue => MonthCell(
        month: m.month,
        fill: Colors.transparent,
        outline: c.bad,
        glyph: '!',
        tooltip: '${_shortMonth(m.month)}: due, not bought yet',
      ),
      MonthState.pending => MonthCell(
        month: m.month,
        fill: Colors.transparent,
        outline: c.muted,
        glyph: '·',
        tooltip: '${_shortMonth(m.month)}: not due yet',
      ),
    },
];

/// Builds reminder cells: the buy state for the month, with what was sent.
List<MonthCell> reminderCells(
  List<String> months,
  ContributionStatusModel status,
  Map<String, MonthReminders> sent,
  ChartColors c,
) {
  final byMonth = {for (final m in status.months) m.month: m};
  return [
    for (final month in months)
      if (byMonth[month] != null)
        () {
          final m = byMonth[month]!;
          final r = sent[month] ?? const MonthReminders(due: 0, followup: 0);
          final what = [
            if (r.due > 0) '${r.due} reminder',
            if (r.followup > 0) '${r.followup} follow-up',
          ].join(', ');
          final bought = m.state == MonthState.done;
          return MonthCell(
            month: month,
            fill: bought
                ? c.accent
                : (m.state == MonthState.missed ? c.bad : Colors.transparent),
            outline:
                m.state == MonthState.pending || m.state == MonthState.overdue
                ? c.muted
                : null,
            glyph: '${r.due + r.followup}',
            tooltip:
                '${_shortMonth(month)}: ${bought
                    ? 'bought'
                    : m.state == MonthState.missed
                    ? 'missed'
                    : 'not bought yet'}; ${what.isEmpty ? 'no email sent' : '$what sent'}',
          );
        }(),
  ];
}
