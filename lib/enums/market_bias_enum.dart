enum MarketBiasEnum {
  BULLISH(1),
  BEARISH(2),
  NEUTRAL(3);

  const MarketBiasEnum(this.value);

  final int value;

  static MarketBiasEnum fromValue(int value) {
    for (var type in MarketBiasEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid MarketBiasEnum value: $value');
  }
}
