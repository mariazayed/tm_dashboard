enum DecisionStatusEnum {
  ACTIVE(1),
  SUPERSEDED(2),
  REVERSED(3),
  COMPLETED(4);

  const DecisionStatusEnum(this.value);

  final int value;

  static DecisionStatusEnum fromValue(int value) {
    for (var type in DecisionStatusEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid DecisionStatusEnum value: $value');
  }

  String get label {
    switch (this) {
      case DecisionStatusEnum.ACTIVE:
        return 'Active';
      case DecisionStatusEnum.SUPERSEDED:
        return 'Superseded';
      case DecisionStatusEnum.REVERSED:
        return 'Reversed';
      case DecisionStatusEnum.COMPLETED:
        return 'Completed';
    }
  }
}
