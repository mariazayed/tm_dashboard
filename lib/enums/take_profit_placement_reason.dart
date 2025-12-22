enum TakeProfitPlacementReasonEnum {
  FVG_FILL(1),
  LIQUIDITY_SWEEP(2),
  MAJOR_LEVEL(3),
  RISK_MULTIPLE_ACHIEVED(4),
  OPPOSING_OB(5);

  const TakeProfitPlacementReasonEnum(this.value);

  final int value;

  static TakeProfitPlacementReasonEnum fromValue(int value) {
    for (var type in TakeProfitPlacementReasonEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid TakeProfitPlacementReason value: $value');
  }
}
