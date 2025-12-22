import 'package:tm_dashboard/enums/market_state_enum.dart';

import 'base_static_data_model.dart';

class MarketStateModel extends BaseStaticDataModel {
  MarketStateEnum id;
  int order;
  String enName;
  String arName;
  String description;

  MarketStateModel({
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
