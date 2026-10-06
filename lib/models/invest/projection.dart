import 'dart:math' as math;

/// What a monthly plan could grow to under a steady assumed return. These are
/// illustrations, not predictions: real returns are uneven and can be negative.
class Projection {
  const Projection({
    required this.contributedCents,
    required this.finalValueCents,
  });

  /// Everything put in over the horizon, including the starting balance.
  final int contributedCents;
  final int finalValueCents;

  int get growthCents => finalValueCents - contributedCents;

  /// [annualReturn] is the effective yearly rate (0.07 = 7%), compounded
  /// monthly; contributions land at the end of each month.
  ///
  ///     FV = start * (1+r)^n + monthly * ((1+r)^n - 1) / r
  ///
  /// with r the equivalent monthly rate and n the number of months.
  factory Projection.compute({
    required int startCents,
    required int monthlyCents,
    required int years,
    required double annualReturn,
  }) {
    final months = years * 12;
    final contributed = startCents + monthlyCents * months;
    if (months <= 0) {
      return Projection(
        contributedCents: startCents,
        finalValueCents: startCents,
      );
    }
    final double future;
    if (annualReturn == 0) {
      future = contributed.toDouble();
    } else {
      final r = math.pow(1 + annualReturn, 1 / 12) - 1;
      final growth = math.pow(1 + r, months);
      future = startCents * growth + monthlyCents * (growth - 1) / r;
    }
    return Projection(
      contributedCents: contributed,
      finalValueCents: future.round(),
    );
  }
}
