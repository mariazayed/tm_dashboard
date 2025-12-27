import '../enums/scaling_rule_enum.dart';
import 'base_static_data_model.dart';

class ScalingRuleModel extends BaseStaticDataModel {
  ScalingRuleEnum id;

  ScalingRuleModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory ScalingRuleModel.fromJson(dynamic json) {
    return ScalingRuleModel(
      id: ScalingRuleEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
