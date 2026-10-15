import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../services/contribution_service.dart';
import '../../../theme/app_semantic_colors.dart';
import '../value_chart_card.dart';

/// Colours for the Charts screen. One accent for the main series, then the
/// app's own orange and violet, so series are told apart by more than hue
/// (the charts also differ by line style, outline or position).
class ChartColors {
  const ChartColors({
    required this.accent,
    required this.second,
    required this.third,
    required this.muted,
    required this.grid,
    required this.label,
    required this.good,
    required this.bad,
    required this.warn,
    required this.tooltipBg,
    required this.tooltipBorder,
  });

  final Color accent;
  final Color second;
  final Color third;
  final Color muted;
  final Color grid;
  final Color label;
  final Color good;
  final Color bad;
  final Color warn;
  final Color tooltipBg;
  final Color tooltipBorder;

  factory ChartColors.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final s = context.semanticColors;
    return ChartColors(
      accent: dark ? ValueChartCard.valueDark : ValueChartCard.valueLight,
      second: s.orange,
      third: s.violet,
      muted: s.chartAxisLabel,
      grid: s.chartGridLine.withValues(alpha: 0.5),
      label: s.chartAxisLabel,
      good: s.profit,
      bad: s.loss,
      warn: s.warning,
      tooltipBg: s.tooltipBackground,
      tooltipBorder: s.tooltipBorder,
    );
  }
}

class LegendItem {
  const LegendItem(
    this.label,
    this.color, {
    this.dashed = false,
    this.outlined = false,
    this.dot = false,
  });

  final String label;
  final Color color;

  /// A dashed line swatch.
  final bool dashed;

  /// A hollow box swatch.
  final bool outlined;

  /// A round dot swatch.
  final bool dot;
}

/// A titled card with a one-line note, a legend, the chart, and a sentence
/// that says what the chart shows for anyone who cannot see it.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.title,
    required this.child,
    this.note,
    this.legend = const [],
    this.summary,
    this.height = 220,
  });

  final String title;
  final String? note;
  final List<LegendItem> legend;
  final String? summary;
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (note != null) ...[
              const SizedBox(height: 2),
              Text(
                note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (summary != null) ...[
              const SizedBox(height: 8),
              Text(summary!, style: theme.textTheme.bodyMedium),
            ],
            if (legend.isNotEmpty) ...[
              const SizedBox(height: 8),
              InsightLegend(items: legend),
            ],
            const SizedBox(height: 12),
            if (height == null)
              child
            else
              SizedBox(height: height, child: child),
          ],
        ),
      ),
    );
  }
}

class InsightLegend extends StatelessWidget {
  const InsightLegend({super.key, required this.items});

  final List<LegendItem> items;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        for (final i in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _swatch(i),
              const SizedBox(width: 6),
              Flexible(child: Text(i.label, style: style)),
            ],
          ),
      ],
    );
  }

  Widget _swatch(LegendItem i) {
    if (i.dashed) {
      return SizedBox(
        width: 22,
        height: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            3,
            (_) => Container(width: 5, height: 2, color: i.color),
          ),
        ),
      );
    }
    if (i.dot) {
      return Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: i.color, shape: BoxShape.circle),
      );
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: i.outlined ? Colors.transparent : i.color,
        border: i.outlined ? Border.all(color: i.color, width: 1.5) : null,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

/// Calls [load] once and shows [builder] with the result. A failure becomes
/// a quiet card naming the chart, so one broken source never blanks the page.
class InsightLoader<T> extends StatefulWidget {
  const InsightLoader({
    super.key,
    required this.load,
    required this.title,
    required this.builder,
  });

  final Future<T> Function() load;
  final String title;
  final Widget Function(BuildContext context, T data) builder;

  @override
  State<InsightLoader<T>> createState() => _InsightLoaderState<T>();
}

class _InsightLoaderState<T> extends State<InsightLoader<T>> {
  late final Future<T> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          final e = snap.error;
          return InsightCard(
            title: widget.title,
            height: null,
            child: Text(
              e is InvestApiException
                  ? e.message
                  : 'Could not load this chart.',
              key: Key('error-${widget.title}'),
            ),
          );
        }
        if (!snap.hasData) {
          return InsightCard(
            title: widget.title,
            height: 80,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return widget.builder(context, snap.data as T);
      },
    );
  }
}

/// "No data yet" body for a chart that has too little to draw.
class InsightEmpty extends StatelessWidget {
  const InsightEmpty(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(message, textAlign: TextAlign.center));
}

// ---------------------------------------------------------------- chart parts

TextStyle labelStyle(ChartColors c) => TextStyle(color: c.label, fontSize: 11);

FlGridData gridData(ChartColors c) => FlGridData(
  show: true,
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) => FlLine(color: c.grid, strokeWidth: 1),
);

/// Left axis labels without repeating the top edge value.
SideTitles leftTitles(
  ChartColors c,
  String Function(double) format, {
  double reserved = 48,
}) => SideTitles(
  showTitles: true,
  reservedSize: reserved,
  getTitlesWidget: (value, meta) {
    if (value == meta.max) return const SizedBox.shrink();
    return SideTitleWidget(
      meta: meta,
      child: Text(format(value), style: labelStyle(c)),
    );
  },
);

/// Bottom axis labels at whole positions, thinned so they never collide.
SideTitles indexTitles(
  ChartColors c,
  int count,
  String Function(int) label, {
  int target = 5,
}) {
  final step = (count / target).ceil().clamp(1, 1 << 30);
  return SideTitles(
    showTitles: true,
    reservedSize: 26,
    interval: 1,
    getTitlesWidget: (value, meta) {
      final i = value.round();
      if ((value - i).abs() > 0.001 || i < 0 || i >= count || i % step != 0) {
        return const SizedBox.shrink();
      }
      return SideTitleWidget(
        meta: meta,
        child: Text(label(i), style: labelStyle(c)),
      );
    },
  );
}

FlTitlesData titles(SideTitles left, SideTitles bottom) => FlTitlesData(
  topTitles: const AxisTitles(),
  rightTitles: const AxisTitles(),
  leftTitles: AxisTitles(sideTitles: left),
  bottomTitles: AxisTitles(sideTitles: bottom),
);

BarTouchData barTouch(
  ChartColors c,
  String Function(int group, int rod) text,
) => BarTouchData(
  touchTooltipData: BarTouchTooltipData(
    getTooltipColor: (_) => c.tooltipBg,
    tooltipBorder: BorderSide(color: c.tooltipBorder),
    fitInsideHorizontally: true,
    fitInsideVertically: true,
    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
        BarTooltipItem(text(groupIndex, rodIndex), tooltipStyle(c)),
  ),
);

Color _onTooltip(ChartColors c) =>
    ThemeData.estimateBrightnessForColor(c.tooltipBg) == Brightness.dark
    ? Colors.white
    : Colors.black87;

TextStyle tooltipStyle(ChartColors c) =>
    TextStyle(color: _onTooltip(c), fontSize: 12);

LineTouchData lineTouch(
  ChartColors c,
  String Function(List<LineBarSpot> spots) text,
) => LineTouchData(
  touchSpotThreshold: 24,
  touchTooltipData: LineTouchTooltipData(
    getTooltipColor: (_) => c.tooltipBg,
    tooltipBorder: BorderSide(color: c.tooltipBorder),
    fitInsideHorizontally: true,
    fitInsideVertically: true,
    getTooltipItems: (spots) => [
      for (var i = 0; i < spots.length; i++)
        i == 0 ? LineTooltipItem(text(spots), tooltipStyle(c)) : null,
    ],
  ),
);
