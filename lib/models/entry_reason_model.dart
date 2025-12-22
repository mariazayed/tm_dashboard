import 'package:tm_dashboard/enums/entry_reason_enum.dart';

import 'base_static_data_model.dart';

class EntryReasonModel extends BaseStaticDataModel {
  EntryReasonEnum id;
  int order;
  String enName;
  String arName;
  String description;

  EntryReasonModel({
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
