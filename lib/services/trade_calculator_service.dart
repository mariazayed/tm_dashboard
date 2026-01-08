import '../enums/trade_direction_enum.dart';

class TradeCalculatorService {
  static double? calculatePriceDifference({
    required TradeDirectionEnum direction,
    required double entry,
    required double target,
  }) {
    final diff = direction == TradeDirectionEnum.LONG
        ? target - entry
        : entry - target;
    return diff;
  }

  static double calculatePips(double priceDiff) {
    return priceDiff * 10;
  }

  static double calculateUsd(double priceDiff, double lotSize) {
    return priceDiff * lotSize * 100;
  }

  static double? calculateRR(double? slUsd, double? tpUsd) {
    if (slUsd == null || tpUsd == null || slUsd <= 0) {
      return null;
    }
    return tpUsd / slUsd;
  }
}
