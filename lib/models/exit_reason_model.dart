import 'package:tm_dashboard/enums/exit_reason_enum.dart';

import 'base_static_data_model.dart';

class ExitReasonModel extends BaseStaticDataModel {
  ExitReasonEnum id;

  ExitReasonModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory ExitReasonModel.fromJson(dynamic json) {
    return ExitReasonModel(
      id: ExitReasonEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
