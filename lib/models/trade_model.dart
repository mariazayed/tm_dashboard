import 'package:tm_dashboard/enums/trade_direction_enum.dart';
import 'package:tm_dashboard/models/asset_model.dart';

class TradeModel {
  final DateTime entryDateTime;
  final DateTime exitDateTime;
  final Asset asset;
  final TradeDirectionEnum direction;
  final double entryPrice;
  final double exitPrice;
  final double lot;
  final double pips;
  final double profit;

  TradeModel({
    required this.entryDateTime,
    required this.exitDateTime,
    required this.asset,
    required this.direction,
    required this.entryPrice,
    required this.exitPrice,
    required this.lot,
    required this.pips,
    required this.profit,
  });

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    return TradeModel(
      entryDateTime: DateTime.parse(json['entryDateTime']),
      exitDateTime: DateTime.parse(json['exitDateTime']),
      asset: json['asset'],
      direction: json['direction'],
      entryPrice: (json['entryPrice'] as num).toDouble(),
      exitPrice: (json['exitPrice'] as num).toDouble(),
      lot: (json['lot'] as num).toDouble(),
      pips: (json['pips'] as num).toDouble(),
      profit: (json['profit'] as num).toDouble(),
    );
  }
}
