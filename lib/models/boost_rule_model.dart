import 'base_static_data_model.dart';

class BoostRuleModel extends BaseStaticDataModel {
  int id;

  BoostRuleModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory BoostRuleModel.fromJson(dynamic json) {
    return BoostRuleModel(
      id: json["id"],
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
