import 'package:tm_dashboard/enums/trade_direction_enum.dart';

import 'base_static_data_model.dart';

class TradeDirectionModel extends BaseStaticDataModel {
  TradeDirectionEnum id;

  TradeDirectionModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory TradeDirectionModel.fromJson(dynamic json) {
    return TradeDirectionModel(
      id: TradeDirectionEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
