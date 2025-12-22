enum InvalidationConditionEnum {
  CHOCH_AGAINST_DIRECTION(1),
  BREAK_OF_OB(2),
  SWEEP_FAILURE(3),
  NEWS_VOLATILITY(4),
  VOLUME_DIVERGENCE(5);

  const InvalidationConditionEnum(this.value);

  final int value;

  static InvalidationConditionEnum fromValue(int value) {
    for (var type in InvalidationConditionEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid DayOfWeekEnum value: $value');
  }
}
