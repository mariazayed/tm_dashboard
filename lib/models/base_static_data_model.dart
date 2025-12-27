class BaseStaticDataModel {
  int order;
  String enName;
  String arName;
  String description;

  BaseStaticDataModel({
    required this.order,
    required this.enName,
    required this.arName,
    required this.description,
  });

  // factory BaseStaticDataModel.fromJson(dynamic json) {
  //   return BaseStaticDataModel(
  //     arName: json["arName"],
  //     enName: json["enName"],
  //     order: json["order"],
  //     description: json["description"],
  //   );
}
