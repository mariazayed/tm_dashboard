import '../enums/trade_direction_enum.dart';
import '../models/asset_model.dart';

class TradeCalculatorService {
  static double calculatePriceDifference({
    required TradeDirectionEnum direction,
    required double entry,
    required double target,
  }) {
    final diff = direction == TradeDirectionEnum.LONG
        ? target - entry
        : entry - target;
    return diff;
  }

  static double calculatePips({
    required Asset asset,
    required TradeDirectionEnum direction,
    required double entry,
    required double exit,
  }) {
    final pipSize = asset.pipSize;
    if (pipSize == null || pipSize <= 0) {
      return 0;
    }

    final priceDiff = calculatePriceDifference(
      direction: direction,
      entry: entry,
      target: exit,
    );
    return priceDiff / pipSize;
  }

  static double? calculateRR(double? slUsd, double? tpUsd) {
    if (slUsd == null || tpUsd == null || slUsd <= 0) {
      return null;
    }
    return tpUsd / slUsd;
  }
}
