import 'package:tm_dashboard/models/static_data.dart';

import '../enums/strategy_tag_enum.dart';
import '../services/static_data_service.dart';
import 'strategy_tag_model.dart';

class Strategy {
  final int id;
  final String name;
  final String link;
  final List<StrategyTagModel> tags;

  Strategy({
    required this.id,
    required this.name,
    required this.link,
    required this.tags,
  });

  static Future<Strategy> fromJson(Map<String, dynamic> json) async {
    return Strategy(
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
    if (tags.isEmpty) return [];
    final staticData = await StaticDataService.getAll();
    return tags.map((tagId) {
      for (final tag in staticData.strategyTags) {
        if (tag.id == StrategyTagEnum.fromValue(tagId)) return tag;
      }
      throw ArgumentError('Invalid argument in getTagById() (value = $tagId)');
    }).toList();
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
