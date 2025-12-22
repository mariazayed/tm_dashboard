import 'package:tm_dashboard/enums/invalidation_condition_enum.dart';

import 'base_static_data_model.dart';

class InvalidationConditionModel extends BaseStaticDataModel {
  InvalidationConditionEnum id;
  int order;
  String enName;
  String arName;
  String description;

  InvalidationConditionModel({
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
