enum EntryTypeEnum {
  INSTANT(1),
  LIMIT(2),
  CONFIRMATION(3),
  BREAKOUT(4);

  const EntryTypeEnum(this.value);

  final int value;

  static EntryTypeEnum fromValue(int value) {
    for (var type in EntryTypeEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid EntryTypeEnum value: $value');
  }
}
