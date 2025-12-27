import 'package:tm_dashboard/enums/stop_loss_placement_reason_enum.dart';

import 'base_static_data_model.dart';

class StopLossPlacementReasonModel extends BaseStaticDataModel {
  StopLossPlacementReasonEnum id;

  StopLossPlacementReasonModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory StopLossPlacementReasonModel.fromJson(dynamic json) {
    return StopLossPlacementReasonModel(
      id: StopLossPlacementReasonEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
