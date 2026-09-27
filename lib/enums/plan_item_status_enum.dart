/// Outcome of a planner item (weekly task / monthly objective). Mirrors
/// tm-server's PlanItemStatusEnum -- serialized as its int value.
enum PlanItemStatusEnum {
  PLANNED(1),
  DONE(2),
  PARTIAL(3),
  MISSED(4);

  const PlanItemStatusEnum(this.value);

  final int value;

  static PlanItemStatusEnum fromValue(int? value) {
    for (final type in PlanItemStatusEnum.values) {
      if (type.value == value) return type;
    }
    return PlanItemStatusEnum.PLANNED;
  }

  String get label {
    switch (this) {
      case PlanItemStatusEnum.PLANNED:
        return 'Not evaluated';
      case PlanItemStatusEnum.DONE:
        return 'Done';
      case PlanItemStatusEnum.PARTIAL:
        return 'Partial';
      case PlanItemStatusEnum.MISSED:
        return 'Missed';
    }
  }

  bool get isEvaluated => this != PlanItemStatusEnum.PLANNED;
}
