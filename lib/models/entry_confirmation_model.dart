import 'package:tm_dashboard/enums/entry_confirmation_enum.dart';

import 'base_static_data_model.dart';

class EntryConfirmationModel extends BaseStaticDataModel {
  EntryConfirmationEnum id;
  int order;
  String enName;
  String arName;
  String description;

  EntryConfirmationModel({
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
