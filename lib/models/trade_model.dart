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
  String? notes;

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
    this.notes,
  });

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    return TradeModel(
      entryDateTime: DateTime.parse(json['entryDateTime']),
      exitDateTime: DateTime.parse(json['exitDateTime']),
      asset: Asset.fromJson(json['asset']),
      direction: TradeDirectionEnum.fromValue(json['direction']),
      entryPrice: (json['entryPrice'] as num).toDouble(),
      exitPrice: (json['exitPrice'] as num).toDouble(),
      lot: (json['lotSize'] as num).toDouble(),
      pips: (json['pips'] as num).toDouble(),
      profit: (json['pnl'] as num).toDouble(),
      notes: json['notes'] ?? "",
    );
  }
}
