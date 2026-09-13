import 'package:flutter_test/flutter_test.dart';
import 'package:tm_dashboard/screens/risk_management/risk_metrics.dart';

void main() {
  group('RiskMetrics', () {
    test('calculates expectancy in R, dollars, and percent correctly', () {
      final metrics = RiskMetrics(
        capital: 1000,
        winRate: 0.5,
        riskPct: 0.04,
        rrr: 2,
        trades: 20,
        tradesPerDay: 2,
      );

      expect(metrics.avgRiskPerTrade, closeTo(40, 0.0001));
      expect(metrics.averageRPerTrade, closeTo(40, 0.0001));
      expect(metrics.avgRewardPerTrade, closeTo(80, 0.0001));
      expect(metrics.expectancyR, closeTo(0.5, 0.0001));
      expect(
        metrics.avgRiskPerTrade * metrics.expectancyR,
        closeTo(20, 0.0001),
      );
      expect(metrics.avgTradeReturnPct, closeTo(2, 0.0001));
    });

    test('calculates time estimates from trade count and trades per day', () {
      final metrics = RiskMetrics(
        capital: 1000,
        winRate: 0.5,
        riskPct: 0.04,
        rrr: 2,
        trades: 20,
        tradesPerDay: 2,
      );

      expect(metrics.days, closeTo(10, 0.0001));
      expect(metrics.weeks, closeTo(2, 0.0001));
      expect(metrics.months, closeTo(0.5, 0.0001));
    });

    test('zero risk has zero risk of ruin', () {
      final metrics = RiskMetrics(
        capital: 1000,
        winRate: 0.5,
        riskPct: 0,
        rrr: 2,
        trades: 20,
        tradesPerDay: 2,
      );

      expect(metrics.riskOfRuin, 0);
    });
  });
}
