import 'package:flutter/cupertino.dart';
import 'package:tm_dashboard/models/strategy_model.dart';

import '../../../enums/trade_direction_enum.dart';
import '../../../models/asset_model.dart';

class TradeDraft {
  final String id = UniqueKey().toString();

  Asset asset;
  Strategy? strategy;
  TradeDirectionEnum signal = TradeDirectionEnum.LONG;
  double entryPrice = 0;
  double exitPrice = 0;
  double lot = 0.01;
  double sl = 0;
  double tp = 0;
  String notes = '';
  double pips = 0;
  double profit = 0;

  TradeDraft({required this.asset, this.strategy});

  Map<String, dynamic> toJson({
    required DateTime entryDateTime,
    required DateTime exitDateTime,
  }) {
    dynamic json = {
      'entryDateTime': entryDateTime.toIso8601String(),
      'exitDateTime': exitDateTime.toIso8601String(),
      'asset': asset.id,
      'direction': signal.value,
      'entryPrice': entryPrice,
      'exitPrice': exitPrice,
      'lotSize': lot,
      'slPrice': sl,
      'tpPrice': tp,
      'notes': notes,
      'pips': pips,
      'pnl': profit,
    };

    if (strategy != null) {
      json['strategy'] = strategy!.id;
    }

    return json;
  }
}
