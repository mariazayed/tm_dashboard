import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/day_model.dart';
import '../../models/trade_model.dart';
import '../../theme/app_theme.dart';
import 'calendar_state.dart';
import 'day_edit_dialog.dart';

/// Light -> stronger steps for the day-cell heatmap tint, one arm per side
/// of zero. Deliberately capped short of Material's darker steps so the
/// charcoal day-number/status text stays legible at every intensity --
/// this is shading, not the number itself, which is always drawn in the
/// fixed [_kProfitColor]/[_kLossColor] above regardless of tint strength.
const List<Color> _kGreenRamp = [
  Color(0xFFEFF8F0),
  Color(0xFFDCEEDD),
  Color(0xFFC8E6C9),
  Color(0xFFA5D6A7),
  Color(0xFF86D18C),
];

const List<Color> _kRedRamp = [
  Color(0xFFFDF1F0),
  Color(0xFFFBDFDD),
  Color(0xFFFFCDD2),
  Color(0xFFEF9A9A),
  Color(0xFFE57373),
];

const Color _kTintTextColor = AppPalette.gray800;
const Color _kTintMetaTextColor = AppPalette.gray600;
const Color _kTintProfitTextColor = Color(0xFF15803D);
const Color _kTintLossTextColor = Color(0xFF991B1B);

/// Interpolates along a light->strong ramp for a 0..1 intensity, so the
/// heatmap tint is computed rather than picked per-cell.
Color _heatColor(List<Color> ramp, double t) {
  final clamped = t.clamp(0.0, 1.0);
  final scaled = clamped * (ramp.length - 1);
  final lowIndex = scaled.floor();
  final highIndex = scaled.ceil();
  final localT = scaled - lowIndex;
  return Color.lerp(ramp[lowIndex], ramp[highIndex], localT)!;
}

class WeekRow extends StatelessWidget {
  final List<DayModel> row;
  final int placeholders;

  /// This month's trades keyed by day-of-month, so each cell can show a
  /// trades overview (count + net P&L) without every cell fetching its
  /// own data.
  final Map<int, List<Trade>> tradesByDay;

  /// Largest absolute net P&L seen across the whole month currently on
  /// screen -- the denominator the heatmap tint is scaled against, so a
  /// day's shade reflects its size *relative to this month's other days*
  /// rather than an arbitrary fixed threshold.
  final double maxAbsPnl;

  const WeekRow({
    required this.row,
    this.placeholders = 0,
    this.tradesByDay = const {},
    this.maxAbsPnl = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        if (i < placeholders) return const Expanded(child: SizedBox());

        final dayIndex = i - placeholders;
        if (dayIndex >= row.length) {
          return const Expanded(child: SizedBox());
        }

        final DayModel day = row[dayIndex];
        final List<Trade> dayTrades = tradesByDay[day.date.day] ?? const [];

        return Expanded(
          child: _DayCell(
            day: day,
            trades: dayTrades,
            maxAbsPnl: maxAbsPnl,
            onOpen: () => _openDayDialog(context, day, dayTrades),
          ),
        );
      }),
    );
  }

  void _openDayDialog(BuildContext context, DayModel day, List<Trade> trades) {
    final cubit = context.read<CalendarCubit>();
    showDialog(
      context: context,
      builder: (_) => DayEditDialog(day: day, cubit: cubit, trades: trades),
    );
  }
}

/// One calendar day cell. Extracted as its own stateful widget so it can
/// track hover locally (same pattern TradeRowTile uses elsewhere in the
/// app) and lift slightly on hover for a more interactive, modern feel.
class _DayCell extends StatefulWidget {
  final DayModel day;
  final List<Trade> trades;
  final double maxAbsPnl;
  final VoidCallback onOpen;

  const _DayCell({
    required this.day,
    required this.trades,
    required this.maxAbsPnl,
    required this.onOpen,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hovering = false;

  DayModel get day => widget.day;

  /// Emoji for each exact psychology score
  String _emojiForScore(int value) {
    switch (value) {
      case 1:
        return "😡";
      case 2:
        return "😖";
      case 3:
        return "😞";
      case 4:
        return "😕";
      case 5:
        return "😐";
      case 6:
        return "🙂";
      case 7:
        return "😌";
      case 8:
        return "😎";
      case 9:
        return "🚀";
      case 10:
        return "🧠🔥";
      default:
        return "";
    }
  }

  /// Background color for each psychology score
  Color? _backgroundForScore(int value) {
    switch (value) {
      case 1:
        return const Color(0xFFFFCDD2); // 😡 strong red
      case 2:
        return const Color(0xFFFFE0E0); // 😖 soft red
      case 3:
        return const Color(0xFFFFCCBC); // 😞 orange-red
      case 4:
        return const Color(0xFFFFE0B2); // 😕 light orange
      case 5:
        return const Color(0xFFE0E0E0); // 😐 neutral grey
      case 6:
        return const Color(0xFFC8E6C9); // 🙂 light green
      case 7:
        return const Color(0xFFA5D6A7); // 😌 calm green
      case 8:
        return const Color(0xFFB3E5FC); // 😎 cool blue
      case 9:
        return const Color(0xFFD1C4E9); // 🚀 purple
      case 10:
        return const Color(0xFFFFF59D); // 🧠🔥 gold
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final trades = widget.trades;
    final hasTrades = trades.isNotEmpty;
    final double netPnl = trades.fold(0.0, (sum, t) => sum + t.profit);

    final today = DateTime.now();
    final isToday =
        day.date.year == today.year &&
        day.date.month == today.month &&
        day.date.day == today.day;

    Color backgroundColor;
    Color textColor = colorScheme.onSurface;
    Color metaTextColor = colorScheme.onSurfaceVariant;
    double opacity = 1.0;
    bool usesLightTint = false;

    /// ✅ Psychology background (takes priority over the trades heatmap --
    /// it's a deliberate, user-set rating for the day)
    if (day.psychologyRate != null) {
      backgroundColor =
          _backgroundForScore(day.psychologyRate!.value) ?? colorScheme.surface;
      textColor = _kTintTextColor;
      metaTextColor = _kTintMetaTextColor;
      usesLightTint = true;
    } else if (isToday) {
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      textColor = Theme.of(context).colorScheme.onPrimaryContainer;
      metaTextColor = Theme.of(context).colorScheme.onPrimaryContainer;
    } else if (day.noWork) {
      backgroundColor = colorScheme.surfaceContainerHigh;
      textColor = colorScheme.onSurfaceVariant;
      opacity = 0.6;
    } else if (day.ended) {
      backgroundColor = colorScheme.surface;
      textColor = colorScheme.onSurfaceVariant;
      opacity = 0.8;
    } else if (day.weekend) {
      backgroundColor = semantic.orange.withValues(alpha: 0.12);
      textColor = semantic.orange;
    } else if (hasTrades && netPnl == 0) {
      /// ✅ Breakeven: the neutral midpoint between the win/loss ramps,
      /// rather than defaulting into the green arm.
      backgroundColor = colorScheme.surfaceContainerHigh;
    } else if (hasTrades) {
      /// ✅ Trades heatmap: tint scaled by this day's net P&L relative to
      /// the strongest day this month, with a floor so even a small P&L
      /// day reads as visibly green/red rather than near-white.
      final relative = widget.maxAbsPnl <= 0
          ? 1.0
          : (netPnl.abs() / widget.maxAbsPnl).clamp(0.0, 1.0);
      final intensity = 0.15 + 0.85 * relative;
      backgroundColor = netPnl > 0
          ? _heatColor(_kGreenRamp, intensity)
          : _heatColor(_kRedRamp, intensity);
      textColor = _kTintTextColor;
      metaTextColor = _kTintMetaTextColor;
      usesLightTint = true;
    } else {
      backgroundColor = colorScheme.surface;
    }

    final List<Widget> statusIcons = [
      if (day.isImportant)
        Icon(Icons.star_rounded, size: 15, color: semantic.warning),

      if (day.noWork)
        Icon(Icons.block, size: 14, color: colorScheme.onSurfaceVariant),

      if (day.ended)
        Icon(Icons.check_circle_outline, size: 14, color: semantic.profit),

      if (day.weekend)
        Icon(Icons.weekend_outlined, size: 14, color: semantic.orange),

      if (day.notes.isNotEmpty)
        Icon(Icons.note_add, size: 14, color: semantic.info),

      if (day.exists) Icon(Icons.hdr_strong, size: 14, color: semantic.violet),

      /// ✅ Psychology Emoji
      if (day.psychologyRate != null)
        Text(
          _emojiForScore(day.psychologyRate!.value),
          style: const TextStyle(fontSize: 14),
        ),
    ];

    final pnlColor = netPnl > 0
        ? (usesLightTint ? _kTintProfitTextColor : semantic.profit)
        : netPnl < 0
        ? (usesLightTint ? _kTintLossTextColor : semantic.loss)
        : metaTextColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 150) {
          final description =
              '${day.date.day}: ${trades.length} trades, net ${netPnl.toStringAsFixed(2)}';
          return Semantics(
            button: true,
            label: description,
            child: Tooltip(
              message: description,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Material(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: widget.onOpen,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 68),
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isToday
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${day.date.day}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (hasTrades)
                            Icon(Icons.circle, size: 8, color: pnlColor)
                          else if (statusIcons.isNotEmpty)
                            statusIcons.first
                          else
                            const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: widget.onOpen,
            child: Opacity(
              opacity: opacity,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                margin: const EdgeInsets.all(6),
                transform: Matrix4.translationValues(0, _hovering ? -2 : 0, 0),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isToday
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.5)
                        : (_hovering && hasTrades)
                        ? pnlColor.withValues(alpha: 0.35)
                        : colorScheme.outlineVariant,
                    width: isToday ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(
                        alpha: _hovering ? 0.08 : 0.03,
                      ),
                      blurRadius: _hovering ? 16 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                day.date.day.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),

                              /// ✅ Trades overview: net P&L for the day, always
                              /// drawn in the fixed profit/loss color (never
                              /// just the background tint) so it stays legible
                              /// and readable without relying on color alone.
                              /// The trade count sits directly under the P&L
                              /// figure it describes -- not as a separate badge
                              /// up next to the date -- so related numbers are
                              /// grouped together instead of competing for
                              /// attention from opposite corners of the cell.
                              if (hasTrades)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "${netPnl >= 0 ? '+' : ''}${netPnl.toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                            color: pnlColor,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        trades.length == 1
                                            ? "1 trade"
                                            : "${trades.length} trades",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: metaTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const Spacer(),
                              if (statusIcons.isNotEmpty)
                                SizedBox(
                                  height: 16,
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: statusIcons,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      /// ✅ Accent bar: a crisp, always-solid-color strip so the
                      /// win/loss signal reads at a glance even before the
                      /// tinted background is consciously noticed.
                      if (hasTrades)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: _hovering ? 5 : 3,
                          color: pnlColor,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
