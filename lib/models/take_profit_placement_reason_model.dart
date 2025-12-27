import 'package:tm_dashboard/enums/take_profit_placement_reason.dart';

import 'base_static_data_model.dart';

class TakeProfitPlacementReasonModel extends BaseStaticDataModel {
  TakeProfitPlacementReasonEnum id;

  TakeProfitPlacementReasonModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory TakeProfitPlacementReasonModel.fromJson(dynamic json) {
    return TakeProfitPlacementReasonModel(
      id: TakeProfitPlacementReasonEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
