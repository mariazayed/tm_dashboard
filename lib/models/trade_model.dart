import 'package:tm_dashboard/enums/trade_direction_enum.dart';
import 'package:tm_dashboard/models/asset_model.dart';
import 'package:tm_dashboard/models/strategy_model.dart';

class Trade {
  final DateTime entryDateTime;
  final DateTime exitDateTime;
  final Asset asset;
  final Strategy? strategy;
  final TradeDirectionEnum direction;
  final double entryPrice;
  final double exitPrice;
  final double lot;
  final double pips;
  final double profit;
  String? notes;

  static Future<Trade> fromJson(Map<String, dynamic> json) async {
    return Trade(
      entryDateTime: DateTime.parse(json['entryDateTime']),
      exitDateTime: DateTime.parse(json['exitDateTime']),
      asset: Asset.fromJson(json['asset']),
      strategy: json['strategy'] != null
          ? await Strategy.fromJson(json['strategy'])
          : null,
      direction: TradeDirectionEnum.fromValue(json['direction']),
      entryPrice: (json['entryPrice'] as num).toDouble(),
      exitPrice: (json['exitPrice'] as num).toDouble(),
      lot: (json['lotSize'] as num).toDouble(),
      pips: (json['pips'] as num).toDouble(),
      profit: (json['pnl'] as num).toDouble(),
      notes: json['notes'] ?? "",
    );
  }

  Trade({
    required this.entryDateTime,
    required this.exitDateTime,
    required this.asset,
    required this.direction,
    required this.entryPrice,
    required this.exitPrice,
    required this.lot,
    required this.pips,
    required this.profit,
    this.strategy,
    this.notes,
  });
}
