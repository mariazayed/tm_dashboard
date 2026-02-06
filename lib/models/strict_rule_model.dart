class StrictRuleModel {
  final int id;
  final String text;

  StrictRuleModel({required this.id, required this.text});

  factory StrictRuleModel.fromJson(Map<String, dynamic> json) {
    return StrictRuleModel(id: json['id'], text: json['text']);
  }

  Map<String, dynamic> toJson() => {'text': text};
}
