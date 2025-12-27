import 'package:tm_dashboard/enums/probability_enum.dart';

import 'base_static_data_model.dart';

class ProbabilityModel extends BaseStaticDataModel {
  ProbabilityEnum id;

  ProbabilityModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory ProbabilityModel.fromJson(dynamic json) {
    return ProbabilityModel(
      id: ProbabilityEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
