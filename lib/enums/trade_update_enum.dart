enum TradeUpdateEnum {
  MOVE_SL_TO_BE(1);

  const TradeUpdateEnum(this.value);

  final int value;

  static TradeUpdateEnum fromValue(int value) {
    for (var type in TradeUpdateEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid TradeUpdateEnum value: $value');
  }
}
