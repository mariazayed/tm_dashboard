enum StopLossPlacementReasonEnum {
  STRUCTURE(1),
  VOLATILITY_BASED(2),
  PREVIOUS_HIGH(3),
  PREVIOUS_LOW(4),
  OB_BOUNDARY(5),
  FVG_BOUNDARY(6);

  const StopLossPlacementReasonEnum(this.value);

  final int value;

  static StopLossPlacementReasonEnum fromValue(int value) {
    for (var type in StopLossPlacementReasonEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid StopLossPlacementReasonEnum value: $value');
  }
}
