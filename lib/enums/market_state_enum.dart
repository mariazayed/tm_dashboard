enum MarketStateEnum {
  UPTREND(1),
  DOWNTREND(2),
  DOWNTREND_CORRECTION(3),
  UPTREND_CORRECTION(4),
  CONSOLIDATION(5),
  HIGH_VOLATILITY(6),
  LOW_VOLATILITY(7),
  HIGH_VOLUME(8),
  LOW_VOLUME(9);

  const MarketStateEnum(this.value);

  final int value;

  static MarketStateEnum fromValue(int value) {
    for (var type in MarketStateEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid MarketStateEnum value: $value');
  }
}
