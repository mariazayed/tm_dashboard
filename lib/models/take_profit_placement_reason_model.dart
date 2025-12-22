import 'package:tm_dashboard/enums/take_profit_placement_reason.dart';

import 'base_static_data_model.dart';

class TakeProfitPlacementReasonModel extends BaseStaticDataModel {
  TakeProfitPlacementReasonEnum id;
  int order;
  String enName;
  String arName;
  String description;

  TakeProfitPlacementReasonModel({
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
