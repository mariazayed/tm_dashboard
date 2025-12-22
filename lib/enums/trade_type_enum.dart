enum TradeTypeEnum {
  SCALPING(1),
  INTRADAY(2),
  SWING(3);

  const TradeTypeEnum(this.value);

  final int value;

  static TradeTypeEnum fromValue(int value) {
    for (var type in TradeTypeEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid TradeTypeEnum value: $value');
  }
}
