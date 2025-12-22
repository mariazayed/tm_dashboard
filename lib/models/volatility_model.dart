import 'package:tm_dashboard/enums/volatility_enum.dart';

import 'base_static_data_model.dart';

class VolatilityModel extends BaseStaticDataModel {
  VolatilityEnum id;
  int order;
  String enName;
  String arName;
  String description;

  VolatilityModel({
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
