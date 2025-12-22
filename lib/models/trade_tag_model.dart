import '../enums/trade_tag_enum.dart';
import 'base_static_data_model.dart';

class TradeTagModel extends BaseStaticDataModel {
  TradeTagEnum id;
  int order;
  String enName;
  String arName;
  String description;

  TradeTagModel({
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
