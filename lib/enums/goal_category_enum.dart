enum GoalCategoryEnum {
  PROFIT(1),
  TRADE_QUALITY(2),
  DISCIPLINE(3),
  MANUAL(4);

  const GoalCategoryEnum(this.value);

  final int value;

  static GoalCategoryEnum fromValue(int value) {
    for (var type in GoalCategoryEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid GoalCategoryEnum value: $value');
  }

  String get label {
    switch (this) {
      case GoalCategoryEnum.PROFIT:
        return 'Profit';
      case GoalCategoryEnum.TRADE_QUALITY:
        return 'Trade Quality';
      case GoalCategoryEnum.DISCIPLINE:
        return 'Discipline';
      case GoalCategoryEnum.MANUAL:
        return 'Manual';
    }
  }
}
