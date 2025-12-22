enum EntryConfirmationEnum {
  CANDLE_PATTERN(1),
  BOS(2),
  CHOCH(3),
  BREAKOUT(4),
  RETEST(5),
  LIQUIDITY_SWEEP(6),
  INDICATOR_CONFIRMATION(7),
  NONE(8);

  const EntryConfirmationEnum(this.value);

  final int value;

  static EntryConfirmationEnum fromValue(int value) {
    for (var type in EntryConfirmationEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid EntryConfirmationEnum value: $value');
  }
}
