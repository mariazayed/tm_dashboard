import 'package:tm_dashboard/enums/entry_type_enum.dart';

import 'base_static_data_model.dart';

class EntryTypeModel extends BaseStaticDataModel {
  EntryTypeEnum id;

  EntryTypeModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory EntryTypeModel.fromJson(dynamic json) {
    return EntryTypeModel(
      id: EntryTypeEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
