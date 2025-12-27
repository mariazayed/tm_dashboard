import 'package:tm_dashboard/enums/market_state_enum.dart';

import 'base_static_data_model.dart';

class MarketStateModel extends BaseStaticDataModel {
  MarketStateEnum id;

  MarketStateModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory MarketStateModel.fromJson(dynamic json) {
    return MarketStateModel(
      id: MarketStateEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
