enum EntryReasonEnum {
  TREND_CONTINUATION(1),
  TREND_REVERSAL(2),
  LIQUIDITY_SWEEP(3),
  RETEST(4),
  BREAKOUT(5),
  PULLBACK(6),
  OB_MITIGATION(7),
  FVG_MITIGATION(8);

  const EntryReasonEnum(this.value);

  final int value;

  static EntryReasonEnum fromValue(int value) {
    for (var type in EntryReasonEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid EntryReasonEnum value: $value');
  }
}
