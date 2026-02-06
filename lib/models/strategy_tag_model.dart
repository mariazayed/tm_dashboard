import '../enums/strategy_tag_enum.dart';
import 'base_static_data_model.dart';

class StrategyTagModel extends BaseStaticDataModel {
  StrategyTagEnum id;

  StrategyTagModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory StrategyTagModel.fromJson(dynamic json) {
    return StrategyTagModel(
      id: StrategyTagEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
