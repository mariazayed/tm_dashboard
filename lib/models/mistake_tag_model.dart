import 'package:tm_dashboard/enums/mistake_tag_enum.dart';

import 'base_static_data_model.dart';

class MistakeTagModel extends BaseStaticDataModel {
  MistakeTagEnum id;

  MistakeTagModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory MistakeTagModel.fromJson(dynamic json) {
    return MistakeTagModel(
      id: MistakeTagEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
