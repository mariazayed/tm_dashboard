import 'package:flutter/material.dart';

/// A row of fields or summary panels that stacks at narrow local widths.
/// Expanded/Flexible children retain their desktop flex and become natural
/// height, full-width children on phones; horizontal gaps become vertical.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.children,
    this.breakpoint = 600,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;
  final double breakpoint;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth >= breakpoint) {
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children,
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in children)
            if (child is Spacer)
              const SizedBox(height: 12)
            else if (child is Flexible)
              child.child
            else if (child is SizedBox && child.child == null)
              SizedBox(height: child.width ?? child.height)
            else
              child,
        ],
      );
    },
  );
}
