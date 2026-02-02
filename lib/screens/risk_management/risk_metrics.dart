import 'dart:math';

/// Corrected RiskMetrics class with proper theoretical math
/// and Monte-Carlo simulation for equity curves.
///
/// - Theoretical metrics are calculated purely from inputs.
/// - Monte-Carlo simulation shows one random possible equity path.
/// - All variable names are kept the same as in the original code.
class RiskMetrics {
  // ===== Inputs =====
  final double capital;
  final double winRate;     // 0–1
  final double riskPct;     // 0–1
  final double rrr;
  final int trades;
  final int tradesPerDay;

  // ===== Monte-Carlo / Simulation outputs =====
  late final List<double> equityCurve;
  late final double finalCapital;
  late final double maxDrawdownPct;
  late final int wins;
  late final int losses;

  // ===== Theoretical metrics =====
  late final double expectancyR;
  late final double averageRPerTrade;
  late final double avgTradeReturnPct;
  late final double avgRiskPerTrade;
  late final double avgRewardPerTrade;
  late final double riskOfRuin;

  // ===== Time metrics =====
  late final double days;
  late final double weeks;
  late final double months;

  RiskMetrics({
    required this.capital,
    required this.winRate,
    required this.riskPct,
    required this.rrr,
    required this.trades,
    required this.tradesPerDay,
  }) {
    // ---------- THEORETICAL METRICS ----------
    expectancyR = _calculateExpectancyR();
    avgTradeReturnPct = expectancyR * riskPct * 100;
    avgRiskPerTrade = capital * riskPct;
    avgRewardPerTrade = avgRiskPerTrade * rrr;
    averageRPerTrade = expectancyR;
    riskOfRuin = _calculateRiskOfRuin();

    // ---------- MONTE-CARLO SIMULATION ----------
    equityCurve = simulateEquityCurve();
    finalCapital = equityCurve.last;
    maxDrawdownPct = _maxDrawdown(equityCurve);

    final results = _countWinsLosses(equityCurve);
    wins = results.$1;
    losses = results.$2;

    // ---------- TIME ESTIMATION ----------
    days = trades / tradesPerDay;
    weeks = days / 5;
    months = days / 20;
  }

  // ---------------- THEORETICAL CALCULATIONS ----------------

  /// Expectancy in R units
  /// Meaning: how many "R" you expect to make per trade on average
  double _calculateExpectancyR() {
    return (winRate * rrr) - (1 - winRate);
  }

  /// Risk of ruin approximation for % risk systems
  /// Meaning: probability of very deep drawdown (~90% loss)
  double _calculateRiskOfRuin() {
    if (expectancyR <= 0) return 1.0; // strategy is losing → guaranteed ruin

    // Approximation using Kelly/variance
    final edge = expectancyR;
    final variance = winRate * pow(rrr, 2) + (1 - winRate);

    final ruinExponent = -2 * edge / variance;
    final ruinProbability = exp(ruinExponent / riskPct);

    return min(ruinProbability, 1.0);
  }

  // ---------------- MONTE-CARLO SIMULATION ----------------

  /// Simulate equity curve using compounding % risk
  /// Shows the path your equity could take due to randomness
  List<double> simulateEquityCurve() {
    final random = Random();
    double equity = capital;
    final curve = <double>[equity];

    for (int i = 0; i < trades; i++) {
      final risk = equity * riskPct;
      final win = random.nextDouble() <= winRate;
      equity += win ? risk * rrr : -risk;
      curve.add(equity);
    }

    return curve;
  }

  /// Maximum drawdown calculation from equity curve
  /// Meaning: worst peak-to-valley drop experienced
  double _maxDrawdown(List<double> curve) {
    double peak = curve.first;
    double maxDD = 0;

    for (final v in curve) {
      if (v > peak) peak = v;
      final dd = (peak - v) / peak;
      maxDD = max(maxDD, dd);
    }

    return maxDD * 100;
  }

  /// Count realized wins and losses from Monte-Carlo simulation
  /// Note: purely informational, not used in theoretical metrics
  (int, int) _countWinsLosses(List<double> curve) {
    int w = 0;
    int l = 0;

    for (int i = 1; i < curve.length; i++) {
      if (curve[i] > curve[i - 1]) {
        w++;
      } else {
        l++;
      }
    }

    return (w, l);
  }
}


/**
 * 📝 Explanation of Metrics (using your variable names)
    Variable	Meaning
    expectancyR	Average "R" you earn per trade (positive = profitable system)
    averageRPerTrade	Same as expectancyR (kept for consistency)
    avgTradeReturnPct	% your account grows per trade on average (theoretical)
    avgRiskPerTrade	Dollars risked per trade (first trade)
    avgRewardPerTrade	Dollars won per winning trade (first trade)
    riskOfRuin	Probability of very deep account drawdown (~90%)
    equityCurve	Simulated equity over time with randomness
    finalCapital	Ending account balance after simulation
    maxDrawdownPct	Worst % drop from peak in the simulation
    wins / losses	Realized wins/losses in simulation (informational only)
    days / weeks / months	Time equivalent of the number of trades
 */