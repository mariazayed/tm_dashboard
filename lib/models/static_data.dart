import 'package:tm_dashboard/models/probability_model.dart';
import 'package:tm_dashboard/models/scaling_rule_model.dart';
import 'package:tm_dashboard/models/session_model.dart';
import 'package:tm_dashboard/models/stop_loss_placement_reason_model.dart';
import 'package:tm_dashboard/models/take_profit_placement_reason_model.dart';
import 'package:tm_dashboard/models/trade_direction_model.dart';
import 'package:tm_dashboard/models/trade_tag_model.dart';
import 'package:tm_dashboard/models/trade_update_model.dart';
import 'package:tm_dashboard/models/volatility_model.dart';

import 'boost_rule_model.dart';
import 'entry_confirmation_model.dart';
import 'entry_reason_model.dart';
import 'entry_type_model.dart';
import 'entry_zone_type_model.dart';
import 'exit_reason_model.dart';
import 'invalidation_condition_model.dart';
import 'market_bias_model.dart';
import 'market_state_model.dart';

class StaticDataResponse {
  List<TradeDirectionModel> tradeDirections;
  List<MarketBiasModel> marketBiases;
  List<MarketStateModel> marketStates;
  List<EntryReasonModel> entryReasons;
  List<EntryConfirmationModel> entryConfirmations;
  List<EntryZoneTypeModel> entryZoneTypes;
  List<InvalidationConditionModel> invalidationConditions;
  List<ProbabilityModel> probabilities;
  List<VolatilityModel> volatilities;
  List<ScalingRuleModel> scalingRules;
  List<BoostRuleModel> boostRules;
  List<StopLossPlacementReasonModel> stopLossPlacementReasons;
  List<TakeProfitPlacementReasonModel> takeProfitPlacementReasons;
  List<EntryTypeModel> entryTypes;
  List<SessionModel> sessions;
  List<TradeTagModel> tradeTags;
  List<TradeUpdateModel> tradeUpdates;
  List<ExitReasonModel> exitReasons;

  StaticDataResponse({
    required this.tradeDirections,
    required this.marketBiases,
    required this.marketStates,
    required this.entryReasons,
    required this.entryConfirmations,
    required this.entryZoneTypes,
    required this.invalidationConditions,
    required this.probabilities,
    required this.volatilities,
    required this.scalingRules,
    required this.boostRules,
    required this.stopLossPlacementReasons,
    required this.takeProfitPlacementReasons,
    required this.entryTypes,
    required this.sessions,
    required this.tradeTags,
    required this.tradeUpdates,
    required this.exitReasons,
  });

  factory StaticDataResponse.fromJson(Map<String, dynamic> json) {
    return StaticDataResponse(
      tradeDirections: json['tradeDirections'],
      marketBiases: json['marketBiases'],
      marketStates: json['marketStates'],
      entryReasons: json['entryReasons'],
      entryConfirmations: json['entryConfirmations'],
      entryZoneTypes: json['entryZoneTypes'],
      invalidationConditions: json['invalidationConditions'],
      probabilities: json['probabilities'],
      volatilities: json['volatilities'],
      scalingRules: json['scalingRules'],
      boostRules: json['boostRules'],
      stopLossPlacementReasons: json['stopLossPlacementReasons'],
      takeProfitPlacementReasons: json['takeProfitPlacementReasons'],
      entryTypes: json['entryTypes'],
      sessions: json['sessions'],
      tradeTags: json['tradeTags'],
      tradeUpdates: json['tradeUpdates'],
      exitReasons: json['exitReasons'],
    );
  }
}
