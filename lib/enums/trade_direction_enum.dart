enum TradeDirectionEnum {
  LONG(1),
  SHORT(2);

  const TradeDirectionEnum(this.value);

  final int value;

  static TradeDirectionEnum fromValue(int value) {
    for (var type in TradeDirectionEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid TradeDirectionEnum value: $value');
  }
}
