import 'package:tm_dashboard/enums/invalidation_condition_enum.dart';

import 'base_static_data_model.dart';

class InvalidationConditionModel extends BaseStaticDataModel {
  InvalidationConditionEnum id;

  InvalidationConditionModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory InvalidationConditionModel.fromJson(dynamic json) {
    return InvalidationConditionModel(
      id: InvalidationConditionEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
