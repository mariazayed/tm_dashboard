class RiskMetrics {
  final double capital;
  final double riskPct;
  final double winRate;
  final double rrr;
  final double trades;
  final double tradesPerDay;

  late final double winningTrades;
  late final double losingTrades;

  late final double riskPerTrade;
  late final double rewardPerTrade;

  late final double expectancy;
  late final double expectancyPct;
  late final double edgeScore;

  late final double dailyRisk;
  late final double dailyReward;
  late final double weeklyRisk;
  late final double weeklyReward;
  late final double monthlyRisk;
  late final double monthlyReward;

  late final double totalWins;
  late final double totalLosses;
  late final double totalAmount;

  late final double days;
  late final double weeks;
  late final double months;

  late final double capitalIncreasePct;

  RiskMetrics({
    required this.capital,
    required this.riskPct,
    required this.winRate,
    required this.rrr,
    required this.trades,
    required this.tradesPerDay,
  }) {
    winningTrades = trades * winRate;
    losingTrades = trades - winningTrades;

    riskPerTrade = capital * riskPct;
    rewardPerTrade = riskPerTrade * rrr;

    expectancy =
        (winRate * rewardPerTrade) -
            ((1 - winRate) * riskPerTrade);

    expectancyPct = expectancy / capital * 100;
    edgeScore = expectancy / riskPerTrade;

    dailyRisk = riskPerTrade * tradesPerDay;
    dailyReward = rewardPerTrade * tradesPerDay;

    weeklyRisk = dailyRisk * 5;
    weeklyReward = dailyReward * 5;

    monthlyRisk = dailyRisk * 20;
    monthlyReward = dailyReward * 20;

    totalWins = winningTrades * rewardPerTrade;
    totalLosses = losingTrades * riskPerTrade;
    totalAmount = totalWins - totalLosses;

    days = trades / tradesPerDay;
    weeks = days / 5;
    months = days / 20;

    capitalIncreasePct = (totalAmount / capital) * 100;
  }

  double pct(double value) => (value / capital) * 100;
}
