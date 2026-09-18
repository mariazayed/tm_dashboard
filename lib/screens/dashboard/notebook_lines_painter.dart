import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class NotebookLinesPainter extends CustomPainter {
  /// Line color to draw with. Optional (rather than required) so existing
  /// `NotebookLinesPainter()` call sites keep compiling -- pass
  /// `Theme.of(context).colorScheme.outlineVariant` from any new caller so
  /// the lines follow light/dark mode.
  const NotebookLinesPainter({this.lineColor});

  final Color? lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor ?? AppPalette.gray300
      ..strokeWidth = 1;

    const double lineSpacing = 24;
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant NotebookLinesPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}
