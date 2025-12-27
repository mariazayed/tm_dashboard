import '../enums/trade_update_enum.dart';
import 'base_static_data_model.dart';

class TradeUpdateModel extends BaseStaticDataModel {
  TradeUpdateEnum id;

  TradeUpdateModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory TradeUpdateModel.fromJson(dynamic json) {
    return TradeUpdateModel(
      id: TradeUpdateEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
