enum DayOfWeekEnum {
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6),
  sunday(7);

  const DayOfWeekEnum(this.value);

  final int value;

  static DayOfWeekEnum fromValue(int value) {
    for (var type in DayOfWeekEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid DayOfWeekEnum value: $value');
  }
}
