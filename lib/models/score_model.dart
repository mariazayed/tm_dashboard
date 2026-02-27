import 'base_static_data_model.dart';

class ScoreModel extends BaseStaticDataModel {
  int id;

  ScoreModel({
    required this.id,
    required super.order,
    required super.enName,
    required super.arName,
    required super.description,
  });

  factory ScoreModel.fromJson(dynamic json) {
    return ScoreModel(
      id: json["id"],
      arName: json["arName"],
      enName: json["enName"],
      order: json["order"],
      description: json["description"],
    );
  }
}
