import 'package:tm_dashboard/enums/entry_confirmation_enum.dart';

import 'base_static_data_model.dart';

class EntryConfirmationModel extends BaseStaticDataModel {
  EntryConfirmationEnum id;

  EntryConfirmationModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory EntryConfirmationModel.fromJson(dynamic json) {
    return EntryConfirmationModel(
      id: EntryConfirmationEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
