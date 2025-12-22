enum VolatilityEnum {
  LOW(1),
  MEDIUM(2),
  HIGH(3);

  const VolatilityEnum(this.value);

  final int value;

  static VolatilityEnum fromValue(int value) {
    for (var type in VolatilityEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid VolatilityEnum value: $value');
  }
}
