enum StrategyTagEnum {
  TREND_TRADE(1),
  REVERSAL_TRADE(2),
  LIQUIDITY_SWEEP_TRADE(3),
  BREAKOUT_TRADE(4),
  FAILED_BREAKOUT_TRADE(5),
  NEWS_TRADE(6),
  SMC_TRADE(7);

  const StrategyTagEnum(this.value);

  final int value;

  static StrategyTagEnum fromValue(int value) {
    for (var type in StrategyTagEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid StrategyTagEnum value: $value');
  }
}
