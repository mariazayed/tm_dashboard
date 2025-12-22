enum DayOfWeekEnum {
  MONDAY(1),
  TUESDAY(2),
  WEDNESDAY(3),
  THURSDAY(4),
  FRIDAY(5),
  SATURDAY(6),
  SUNDAY(7);

  const DayOfWeekEnum(this.value);

  final int value;

  static DayOfWeekEnum fromValue(int value) {
    for (var type in DayOfWeekEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid DayOfWeekEnum value: $value');
  }
}
