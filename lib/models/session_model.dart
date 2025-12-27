import 'package:tm_dashboard/enums/session_enum.dart';

import 'base_static_data_model.dart';

class SessionModel extends BaseStaticDataModel {
  SessionEnum id;

  SessionModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory SessionModel.fromJson(dynamic json) {
    return SessionModel(
      id: SessionEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
