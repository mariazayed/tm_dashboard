import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Domain-specific colors that don't map onto Material's [ColorScheme]
/// roles -- P&L polarity, fl_chart chrome (these charts draw their own text
/// and grid lines outside the widget tree, so they can't read [TextTheme]),
/// categorical accents for non-financial cards, and the dashboard's
/// sticky-note palette.
///
/// Registered on [ThemeData.extensions] in [AppTheme] so every screen
/// reaches it the same way it reaches [ColorScheme]: prefer the
/// `context.semanticColors` extension method (below) over spelling out
/// `Theme.of(context).extension<AppSemanticColors>()!` at every call site.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.profit,
    required this.loss,
    required this.warning,
    required this.info,
    required this.violet,
    required this.orange,
    required this.chartAxisLabel,
    required this.chartGridLine,
    required this.tooltipBackground,
    required this.tooltipBorder,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.noteColors,
  });

  /// Positive P&L, gains, "up" trends -- the app-wide green.
  final Color profit;

  /// Negative P&L, losses, "down" trends -- the app-wide red.
  final Color loss;

  /// Attention/mistake accent (the Mistake Frequency chart).
  final Color warning;

  /// Informational accent, distinct from profit/loss (the Reminder card).
  final Color info;

  /// Categorical accent used by the Expenses chart.
  final Color violet;

  /// Categorical accent used by the Strict Rule card.
  final Color orange;

  /// Axis/label text drawn directly by fl_chart.
  final Color chartAxisLabel;

  /// Gridlines drawn directly by fl_chart.
  final Color chartGridLine;

  /// Background for fl_chart tooltips / loading shimmer highlights.
  final Color tooltipBackground;

  /// Border for fl_chart tooltips.
  final Color tooltipBorder;

  /// Shimmer loading-state placeholder colors (base is the resting tone,
  /// highlight is the brighter tone that sweeps across it).
  final Color shimmerBase;
  final Color shimmerHighlight;

  /// Cycling background palette for the dashboard's sticky notes.
  final List<Color> noteColors;

  static const light = AppSemanticColors(
    profit: AppPalette.green600,
    loss: AppPalette.red500,
    warning: AppPalette.amber500,
    info: AppPalette.blue500,
    violet: AppPalette.violet500,
    orange: AppPalette.orange500,
    chartAxisLabel: AppPalette.gray600,
    chartGridLine: AppPalette.gray300,
    tooltipBackground: Colors.white,
    tooltipBorder: AppPalette.gray100,
    shimmerBase: AppPalette.gray300,
    shimmerHighlight: AppPalette.gray100,
    noteColors: [
      AppPalette.noteYellowLight,
      AppPalette.noteBlueLight,
      AppPalette.noteGreenLight,
      AppPalette.notePinkLight,
      AppPalette.noteOrangeLight,
      AppPalette.notePurpleLight,
    ],
  );

  static const dark = AppSemanticColors(
    profit: AppPalette.green500,
    loss: AppPalette.red400,
    warning: AppPalette.amber500,
    info: AppPalette.blue500,
    violet: AppPalette.violet500,
    orange: AppPalette.orange500,
    chartAxisLabel: AppPalette.gray400,
    chartGridLine: AppPalette.gray700,
    tooltipBackground: AppPalette.gray800,
    tooltipBorder: AppPalette.gray700,
    shimmerBase: AppPalette.gray800,
    shimmerHighlight: AppPalette.gray700,
    noteColors: [
      AppPalette.noteYellowDark,
      AppPalette.noteBlueDark,
      AppPalette.noteGreenDark,
      AppPalette.notePinkDark,
      AppPalette.noteOrangeDark,
      AppPalette.notePurpleDark,
    ],
  );

  @override
  AppSemanticColors copyWith({
    Color? profit,
    Color? loss,
    Color? warning,
    Color? info,
    Color? violet,
    Color? orange,
    Color? chartAxisLabel,
    Color? chartGridLine,
    Color? tooltipBackground,
    Color? tooltipBorder,
    Color? shimmerBase,
    Color? shimmerHighlight,
    List<Color>? noteColors,
  }) {
    return AppSemanticColors(
      profit: profit ?? this.profit,
      loss: loss ?? this.loss,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      violet: violet ?? this.violet,
      orange: orange ?? this.orange,
      chartAxisLabel: chartAxisLabel ?? this.chartAxisLabel,
      chartGridLine: chartGridLine ?? this.chartGridLine,
      tooltipBackground: tooltipBackground ?? this.tooltipBackground,
      tooltipBorder: tooltipBorder ?? this.tooltipBorder,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      noteColors: noteColors ?? this.noteColors,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      profit: Color.lerp(profit, other.profit, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      chartAxisLabel: Color.lerp(chartAxisLabel, other.chartAxisLabel, t)!,
      chartGridLine: Color.lerp(chartGridLine, other.chartGridLine, t)!,
      tooltipBackground:
          Color.lerp(tooltipBackground, other.tooltipBackground, t)!,
      tooltipBorder: Color.lerp(tooltipBorder, other.tooltipBorder, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t)!,
      // A list of colors can't be meaningfully cross-faded value-by-value;
      // snap at the halfway point like most discrete-value theme fields do.
      noteColors: t < 0.5 ? noteColors : other.noteColors,
    );
  }
}

/// Ergonomic accessor so call sites read `context.semanticColors.profit`
/// instead of `Theme.of(context).extension<AppSemanticColors>()!.profit`.
extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
