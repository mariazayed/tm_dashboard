import 'package:tm_dashboard/enums/volatility_enum.dart';

import 'base_static_data_model.dart';

class VolatilityModel extends BaseStaticDataModel {
  VolatilityEnum id;

  VolatilityModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory VolatilityModel.fromJson(dynamic json) {
    return VolatilityModel(
      id: VolatilityEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
