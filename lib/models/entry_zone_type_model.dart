import 'package:tm_dashboard/enums/entry_zone_type_enum.dart';

import 'base_static_data_model.dart';

class EntryZoneTypeModel extends BaseStaticDataModel {
  EntryZoneTypeEnum id;

  EntryZoneTypeModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory EntryZoneTypeModel.fromJson(dynamic json) {
    return EntryZoneTypeModel(
      id: EntryZoneTypeEnum.fromValue(json["id"]),
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
