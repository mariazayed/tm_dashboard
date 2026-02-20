import 'package:tm_dashboard/models/static_data.dart';

import '../enums/strategy_tag_enum.dart';
import '../services/static_data_service.dart';
import 'strategy_tag_model.dart';

class StrategyModel {
  final int id;
  final String name;
  final String link;
  final List<StrategyTagModel> tags;

  StrategyModel({
    required this.id,
    required this.name,
    required this.link,
    required this.tags,
  });

  static Future<StrategyModel> fromJson(Map<String, dynamic> json) async {
    return StrategyModel(
      id: json['id'],
      name: json['name'],
      link: json['link'],
      tags: await getTags((json['tags'] as List).cast<int>()),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'link': link,
    'tags': tags.map((e) => e.id.value).toList(),
  };

  static Future<List<StrategyTagModel>> getTags(List<int> tags) async {
    List<StrategyTagModel> strategyTags = [];

    for (var tagId in tags) {
      StrategyTagModel tagData = await getTagById(tagId);
      strategyTags.add(tagData);
    }

    return strategyTags;
  }

  static Future<StrategyTagModel> getTagById(int tagId) async {
    final StaticDataResponse staticData = await StaticDataService.getAll();

    for (var tagData in staticData.strategyTags) {
      if (tagData.id == StrategyTagEnum.fromValue(tagId)) {
        return tagData;
      }
    }

    throw ArgumentError('Invalid argument in getTagById() (value = $tagId)');
  }
}
