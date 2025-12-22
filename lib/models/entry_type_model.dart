import 'package:tm_dashboard/enums/entry_type_enum.dart';

import 'base_static_data_model.dart';

class EntryTypeModel extends BaseStaticDataModel {
  EntryTypeEnum id;
  int order;
  String enName;
  String arName;
  String description;

  EntryTypeModel({
    required this.id,
    required this.order,
    required this.enName,
    required this.arName,
    required this.description,
  }) : super(
         order: order,
         enName: enName,
         arName: arName,
         description: description,
       );
}
