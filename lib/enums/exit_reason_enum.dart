enum ExitReasonEnum {
  TP_HIT(1),
  SL_HIT(2),
  MANUAL_EXIT(3),
  STRUCTURE_BREAK(4),
  PSYCHOLOGICAL_EXIT(5),
  NEWS_IMPACT(6);

  const ExitReasonEnum(this.value);

  final int value;

  static ExitReasonEnum fromValue(int value) {
    for (var type in ExitReasonEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid ExitReasonEnum value: $value');
  }
}
