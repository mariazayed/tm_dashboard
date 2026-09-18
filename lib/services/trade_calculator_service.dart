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

  // pipSize is the price distance that equals 1 pip for the trade's asset
  // (Asset.pipSize -- e.g. 0.0001 for a 4-decimal forex pair, 0.1 for
  // XAUUSD). Returns 0 when it isn't set rather than guessing at a size
  // that may not apply to this asset.
  static double calculatePips(double priceDiff, double? pipSize) {
    if (pipSize == null || pipSize <= 0) {
      return 0;
    }
    return priceDiff / pipSize;
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
