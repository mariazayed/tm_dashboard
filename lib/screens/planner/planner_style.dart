import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared look-and-feel helpers for the Planner screens: the Focus Area
/// color palette and icon set, plus small hour/date formatters.
class PlannerStyle {
  PlannerStyle._();

  /// Swatches offered when creating a Focus Area (stored as hex strings).
  static const List<String> palette = [
    '#6366F1', // indigo
    '#8B5CF6', // violet
    '#EC4899', // pink
    '#EF4444', // red
    '#F97316', // orange
    '#F59E0B', // amber
    '#22C55E', // green
    '#14B8A6', // teal
    '#06B6D4', // cyan
    '#3B82F6', // blue
    '#64748B', // slate
  ];

  /// Icon keys stored on the server -> Material icons.
  static const Map<String, IconData> icons = {
    'chart': Icons.candlestick_chart_outlined,
    'insights': Icons.insights_outlined,
    'search': Icons.manage_search_outlined,
    'book': Icons.menu_book_outlined,
    'school': Icons.school_outlined,
    'edit': Icons.edit_note_outlined,
    'psychology': Icons.psychology_outlined,
    'self_improvement': Icons.self_improvement_outlined,
    'fitness': Icons.fitness_center_outlined,
    'code': Icons.code_outlined,
    'work': Icons.work_outline,
    'lightbulb': Icons.lightbulb_outline,
    'savings': Icons.savings_outlined,
    'groups': Icons.groups_outlined,
    'home': Icons.home_outlined,
    'bolt': Icons.bolt_outlined,
  };

  static IconData iconFor(String? key) => icons[key] ?? Icons.blur_on_outlined;

  static Color colorFromHex(String? hex) {
    if (hex == null) return const Color(0xFF6366F1);
    var value = hex.replaceAll('#', '');
    if (value.length == 6) value = 'FF$value';
    return Color(int.tryParse(value, radix: 16) ?? 0xFF6366F1);
  }

  /// 6 -> "6h", 7.5 -> "7.5h", 0.25 -> "0.25h".
  static String hours(double h) {
    if (h == h.roundToDouble()) return '${h.toInt()}h';
    final s = h.toStringAsFixed(2);
    return '${s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}h';
  }

  static String pct(double p) => '${p.round()}%';

  /// ISO-8601 week number.
  static int isoWeek(DateTime date) {
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstMonday = firstThursday.subtract(Duration(days: firstThursday.weekday - 1));
    return 1 + thursday.difference(firstMonday).inDays ~/ 7;
  }

  static String weekRange(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    final sameMonth = monday.month == sunday.month;
    final start = DateFormat('MMM d').format(monday);
    final end = DateFormat(sameMonth ? 'd, yyyy' : 'MMM d, yyyy').format(sunday);
    return '$start – $end';
  }

  static const dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
}
