import 'base_static_data_model.dart';

class BoostRuleModel extends BaseStaticDataModel {
  int id;
  int order;
  String enName;
  String arName;
  String description;

  BoostRuleModel({
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
