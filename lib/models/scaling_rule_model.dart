import '../enums/scaling_rule_enum.dart';
import 'base_static_data_model.dart';

class ScalingRuleModel extends BaseStaticDataModel {
  ScalingRuleEnum id;
  int order;
  String enName;
  String arName;
  String description;

  ScalingRuleModel({
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
