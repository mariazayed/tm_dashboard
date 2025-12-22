import 'package:tm_dashboard/enums/invalidation_condition_enum.dart';
import 'package:tm_dashboard/enums/market_bias_enum.dart';

import 'base_static_data_model.dart';

class MarketBiasModel extends BaseStaticDataModel {
  MarketBiasEnum id;
  int order;
  String enName;
  String arName;
  String description;

  MarketBiasModel({
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
