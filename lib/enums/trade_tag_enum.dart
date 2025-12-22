enum TradeTagEnum {
  TREND_TRADE(1),
  REVERSAL_TRADE(2),
  LIQUIDITY_SWEEP_TRADE(3),
  BREAKOUT_TRADE(4),
  FAILED_BREAKOUT_TRADE(5),
  NEWS_TRADE(6),
  SMC_TRADE(7);

  const TradeTagEnum(this.value);

  final int value;

  static TradeTagEnum fromValue(int value) {
    for (var type in TradeTagEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid TradeTagEnum value: $value');
  }
}
