enum ProbabilityEnum {
  LOW(1),
  MEDIUM(2),
  HIGH(3);

  const ProbabilityEnum(this.value);

  final int value;

  static ProbabilityEnum fromValue(int value) {
    for (var type in ProbabilityEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid ProbabilityEnum value: $value');
  }
}
