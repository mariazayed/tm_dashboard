import 'strategy_tag_model.dart';

class StrategyModel {
  final int id;
  final String link;
  final List<StrategyTagModel> tags;

  StrategyModel({required this.id, required this.link, required this.tags});

  factory StrategyModel.fromJson(Map<String, dynamic> json) {
    return StrategyModel(
      id: json['id'],
      link: json['link'],
      tags: (json['tags'] as List<dynamic>)
          .map((e) => StrategyTagModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'link': link,
    'tags': tags.map((e) => e.id.value).toList(),
  };
}
