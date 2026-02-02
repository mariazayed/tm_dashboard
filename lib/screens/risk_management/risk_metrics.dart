import 'dart:math';

class RiskMetrics {
  final double capital;
  final double winRate;     // 0–1
  final double riskPct;     // 0–1
  final double rrr;
  final int trades;
  final int tradesPerDay;

  late final List<double> equityCurve;

  late final double finalCapital;
  late final double totalReturnPct;
  late final double maxDrawdownPct;

  late final double avgRiskPerTrade;     // real average $
  late final double avgRewardPerTrade;   // real average $
  late final double avgTradeReturnPct;   // real %

  late final int wins;
  late final int losses;

  late final double expectancyR;
  late final double averageRPerTrade;

  late final double riskOfRuin;

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
    equityCurve = simulateEquityCurve();
    // Compute single-source-of-truth values once
    finalCapital = equityCurve.last;

    maxDrawdownPct = _maxDrawdown(equityCurve);

    double totalRisk = 0;
    double totalReward = 0;
    int w = 0;
    int l = 0;

    for (int i = 1; i < equityCurve.length; i++) {
      final prev = equityCurve[i - 1];
      final curr = equityCurve[i];
      final change = curr - prev;
      final risk = prev * riskPct;

      totalRisk += risk;

      if (change > 0) {
        totalReward += change;
        w++;
      } else {
        l++;
      }
    }

    wins = w;
    losses = l;

    avgRiskPerTrade = totalRisk / trades;
    avgRewardPerTrade = totalReward / max(1, wins);

    final ratio = equityCurve.last / equityCurve.first;
    avgTradeReturnPct =
        ((pow(ratio, 1.0 / trades)).toDouble() - 1) * 100;

    totalReturnPct =
        ((finalCapital - capital) / capital) * 100;

    expectancyR = (winRate * rrr) - (1 - winRate);
    averageRPerTrade = _averageRMultiple();

    days = trades / tradesPerDay;
    weeks = days / 5;
    months = days / 20;

    riskOfRuin = _riskOfRuin();
  }

  // ---------- True trading model (compounding) ----------
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

  // ---------- Correct drawdown ----------
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

  // ---------- Average R multiple actually achieved ----------
  double _averageRMultiple() {
    double totalR = 0;

    for (int i = 1; i < equityCurve.length; i++) {
      final prev = equityCurve[i - 1];
      final curr = equityCurve[i];
      final change = curr - prev;
      final risk = prev * riskPct;

      totalR += change / risk;
    }

    return totalR / trades;
  }

  double _riskOfRuin() {
    final lossRate = 1 - winRate;
    if (winRate <= 0 || lossRate <= 0) return 1;

    return pow(
      lossRate / winRate,
      capital / avgRiskPerTrade,
    ).toDouble();
  }
}
