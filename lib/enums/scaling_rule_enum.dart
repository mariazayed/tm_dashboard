enum ScalingRuleEnum {
  ADD_ON_BREAK(1),
  ADD_ON_RETEST(2),
  ADD_ON_BOS(3);

  const ScalingRuleEnum(this.value);

  final int value;

  static ScalingRuleEnum fromValue(int value) {
    for (var type in ScalingRuleEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid ScalingRuleEnum value: $value');
  }
}
