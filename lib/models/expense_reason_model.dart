class ExpenseReasonModel {
  final int id;
  final String name;

  ExpenseReasonModel({required this.id, required this.name});

  factory ExpenseReasonModel.fromJson(Map<String, dynamic> json) {
    return ExpenseReasonModel(id: json['id'], name: json['name'] ?? '');
  }

  Map<String, dynamic> toCreateJson() => {'name': name};

  Map<String, dynamic> toUpdateJson() => {'name': name};

  ExpenseReasonModel copyWith({String? name}) {
    return ExpenseReasonModel(id: id, name: name ?? this.name);
  }
}
