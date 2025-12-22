enum ScoreEnum {
  TERRIBLE(1),
  VERY_POOR(2),
  POOR(3),
  BELOW_AVERAGE(4),
  AVERAGE(5),
  ABOVE_AVERAGE(6),
  GOOD(7),
  VERY_GOOD(8),
  EXCELLENT(9),
  WORLD_CLASS(10);

  const ScoreEnum(this.value);

  final int value;

  static ScoreEnum fromValue(int value) {
    for (var type in ScoreEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid ScoreEnum value: $value');
  }
}
