import 'dart:math';

import 'package:flutter/material.dart';

class DashedBorder extends StatelessWidget {
  final Widget child;
  const DashedBorder({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      child: CustomPaint(
        painter: _DashedRectPainter(),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final paint = Paint()
      ..color = Colors.deepPurple
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}