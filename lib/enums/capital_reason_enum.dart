enum CapitalReasonEnum {
  PROFIT(1),
  LOSS(2),
  WITHDRAW(3),
  DEPOSIT(4);

  const CapitalReasonEnum(this.value);

  final int value;

  static CapitalReasonEnum fromValue(int value) {
    for (var type in CapitalReasonEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid CapitalReasonEnum value: $value');
  }
}
