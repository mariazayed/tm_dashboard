enum SessionEnum {
  NEW_YORK_SESSION(1),
  LONDON_SESSION(2),
  ASIAN_SESSION(3);

  const SessionEnum(this.value);

  final int value;

  static SessionEnum fromValue(int value) {
    for (var type in SessionEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid SessionEnum value: $value');
  }
}
