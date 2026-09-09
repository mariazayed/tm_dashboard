enum TradeSourceEnum {
  MANUAL(1),
  AUTO_IMPORTED(2);

  const TradeSourceEnum(this.value);

  final int value;

  static TradeSourceEnum fromValue(int value) {
    for (var type in TradeSourceEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid TradeSourceEnum value: $value');
  }
}
