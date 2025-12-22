import '../enums/trade_tag_enum.dart';
import '../enums/trade_update_enum.dart';
import 'base_static_data_model.dart';

class TradeUpdateModel extends BaseStaticDataModel {
  TradeUpdateEnum id;
  int order;
  String enName;
  String arName;
  String description;

  TradeUpdateModel({
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
