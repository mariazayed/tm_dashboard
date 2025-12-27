import '../enums/trade_tag_enum.dart';
import 'base_static_data_model.dart';

class TradeTagModel extends BaseStaticDataModel {
  TradeTagEnum id;

  TradeTagModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory TradeTagModel.fromJson(dynamic json) {
    return TradeTagModel(
      id: TradeTagEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
