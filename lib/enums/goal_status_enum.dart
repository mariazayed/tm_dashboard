enum GoalStatusEnum {
  ACTIVE(1),
  ACHIEVED(2),
  FAILED(3),
  ARCHIVED(4);

  const GoalStatusEnum(this.value);

  final int value;

  static GoalStatusEnum fromValue(int value) {
    for (var type in GoalStatusEnum.values) {
      if (type.value == value) return type;
    }
    throw ArgumentError('Invalid GoalStatusEnum value: $value');
  }

  String get label {
    switch (this) {
      case GoalStatusEnum.ACTIVE:
        return 'Active';
      case GoalStatusEnum.ACHIEVED:
        return 'Achieved';
      case GoalStatusEnum.FAILED:
        return 'Failed';
      case GoalStatusEnum.ARCHIVED:
        return 'Archived';
    }
  }
}
