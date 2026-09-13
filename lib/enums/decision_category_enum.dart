enum DecisionCategoryEnum {
  TRADING(1),
  INVESTING(2),
  PERSONAL(3),
  SYSTEM(4),
  LEARNING(5),
  OTHERS(6);

  const DecisionCategoryEnum(this.value);

  final int value;

  static DecisionCategoryEnum fromValue(int value) {
    for (var type in DecisionCategoryEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid DecisionCategoryEnum value: $value');
  }

  String get label {
    switch (this) {
      case DecisionCategoryEnum.TRADING:
        return 'Trading';
      case DecisionCategoryEnum.INVESTING:
        return 'Investing';
      case DecisionCategoryEnum.PERSONAL:
        return 'Personal';
      case DecisionCategoryEnum.SYSTEM:
        return 'System';
      case DecisionCategoryEnum.LEARNING:
        return 'Learning';
      case DecisionCategoryEnum.OTHERS:
        return 'Others';
    }
  }
}
