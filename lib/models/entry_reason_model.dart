import 'package:tm_dashboard/enums/entry_reason_enum.dart';

import 'base_static_data_model.dart';

class EntryReasonModel extends BaseStaticDataModel {
  EntryReasonEnum id;

  EntryReasonModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory EntryReasonModel.fromJson(dynamic json) {
    return EntryReasonModel(
      id: EntryReasonEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
