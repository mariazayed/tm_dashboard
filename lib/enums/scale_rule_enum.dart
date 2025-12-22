enum ScaleRuleEnum {
  ADD_ON_BREAK(1),
  ADD_ON_RETEST(2),
  ADD_ON_BOS(3);

  const ScaleRuleEnum(this.value);

  final int value;

  static ScaleRuleEnum fromValue(int value) {
    for (var type in ScaleRuleEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid ScaleRuleEnum value: $value');
  }
}
