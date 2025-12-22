import 'package:tm_dashboard/enums/session_enum.dart';
import 'package:tm_dashboard/enums/stop_loss_placement_reason_enum.dart';

import 'base_static_data_model.dart';

class StopLossPlacementReasonModel extends BaseStaticDataModel {
  StopLossPlacementReasonEnum id;
  int order;
  String enName;
  String arName;
  String description;

  StopLossPlacementReasonModel({
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
