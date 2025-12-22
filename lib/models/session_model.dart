import 'package:tm_dashboard/enums/session_enum.dart';

import 'base_static_data_model.dart';

class SessionModel extends BaseStaticDataModel {
  SessionEnum id;
  int order;
  String enName;
  String arName;
  String description;

  SessionModel({
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
