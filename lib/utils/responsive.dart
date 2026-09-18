import 'package:flutter/material.dart';

/// Shared responsive breakpoints and helpers for the TM dashboard.
///
/// The app shell (see `widgets/menu_bar.dart`) already switches from a
/// permanent sidebar to a drawer+AppBar below [Responsive.tablet] (900px).
/// Individual screens and widgets should use these same breakpoints so the
/// *content* inside that shell also adapts down to phone widths, not just
/// the navigation chrome.
class Responsive {
  Responsive._();

  /// Below this width: phone-sized layout. Single column, stacked
  /// controls, compact paddings, horizontally-scrollable tables.
  static const double mobile = 600;

  /// Below this width (and >= [mobile]): tablet-sized layout. Two columns
  /// where the desktop layout uses three or more, sidebar becomes a drawer
  /// (handled by MainMenu already).
  static const double tablet = 900;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  /// Convenience for widgets that only care about "narrow vs not" using a
  /// [BoxConstraints] from a [LayoutBuilder] instead of [MediaQuery] (useful
  /// when the widget doesn't span the full window width).
  static bool isNarrow(BoxConstraints constraints) =>
      constraints.maxWidth < mobile;

  /// Standard outer page padding that shrinks on small screens instead of
  /// eating into the already-limited content width.
  static EdgeInsets pagePadding(BuildContext context) {
    if (isMobile(context)) return const EdgeInsets.all(12);
    if (isTablet(context)) return const EdgeInsets.all(20);
    return const EdgeInsets.all(28);
  }

  /// Picks a grid column count based on available width. `desktop` is used
  /// at full width, stepping down through `tablet`/`mobile` as space drops.
  static int gridColumns(
    double width, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (width < Responsive.mobile) return mobile;
    if (width < Responsive.tablet) return tablet;
    return desktop;
  }
}

/// Lays out [children] as a [Row] (evenly spaced with [spacing]/[runSpacing])
/// above [breakpoint] and stacks them into a [Column] below it. Use this in
/// place of a hard-coded `Row(children: [...Expanded(...)])` wherever a
/// widget currently assumes desktop width.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.breakpoint = Responsive.mobile,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double breakpoint;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i != 0) SizedBox(height: runSpacing),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i != 0) SizedBox(width: spacing),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

/// Wraps a horizontally-wide widget (a data table, a row of stat tiles that
/// refuses to wrap, etc.) in horizontal scrolling on narrow screens so it
/// never overflows/clips instead of trying to squeeze desktop-only content
/// into a phone width.
class HorizontalScrollOnMobile extends StatelessWidget {
  const HorizontalScrollOnMobile({
    super.key,
    required this.child,
    this.minWidth = 600,
  });

  final Widget child;

  /// The width the child needs to render without being squeezed; below this
  /// viewport width the child is scrolled horizontally instead of shrunk.
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) return child;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: minWidth, child: child),
        );
      },
    );
  }
}
