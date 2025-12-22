import 'package:tm_dashboard/enums/probability_enum.dart';

import 'base_static_data_model.dart';

class ProbabilityModel extends BaseStaticDataModel {
  ProbabilityEnum id;
  int order;
  String enName;
  String arName;
  String description;

  ProbabilityModel({
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
