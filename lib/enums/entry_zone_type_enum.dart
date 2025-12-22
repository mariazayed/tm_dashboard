enum EntryZoneTypeEnum {
  OB(1),
  FVG(2),
  LIQUIDITY(3),
  SUPPORT_RESISTANCE(4),
  SK_LEVELS(5);

  const EntryZoneTypeEnum(this.value);

  final int value;

  static EntryZoneTypeEnum fromValue(int value) {
    for (var type in EntryZoneTypeEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid EntryZoneTypeEnum value: $value');
  }
}
