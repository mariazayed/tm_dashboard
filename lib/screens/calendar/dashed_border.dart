import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class DashedBorder extends StatelessWidget {
  final Widget child;
  const DashedBorder({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: CustomPaint(
        painter: _DashedRectPainter(
          color: Theme.of(context).colorScheme.primary,
        ),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  /// Dash color to draw with. Optional (rather than required) so any
  /// existing `_DashedRectPainter()` call sites keep compiling -- the one
  /// call site in this file passes `Theme.of(context).colorScheme.primary`
  /// so the dashed border follows light/dark mode.
  const _DashedRectPainter({this.color});

  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final paint = Paint()
      ..color = color ?? AppPalette.indigo400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(min(x + dashWidth, size.width), 0), paint);
      canvas.drawLine(Offset(x, size.height), Offset(min(x + dashWidth, size.width), size.height), paint);
      x += dashWidth + dashSpace;
    }

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, min(y + dashWidth, size.height)), paint);
      canvas.drawLine(Offset(size.width, y), Offset(size.width, min(y + dashWidth, size.height)), paint);
      y += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color;
}