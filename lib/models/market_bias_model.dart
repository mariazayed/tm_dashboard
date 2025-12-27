import 'package:tm_dashboard/enums/market_bias_enum.dart';

import 'base_static_data_model.dart';

class MarketBiasModel extends BaseStaticDataModel {
  MarketBiasEnum id;

  MarketBiasModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory MarketBiasModel.fromJson(dynamic json) {
    return MarketBiasModel(
      id: MarketBiasEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
