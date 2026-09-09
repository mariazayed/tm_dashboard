import 'package:tm_dashboard/models/probability_model.dart';
import 'package:tm_dashboard/models/scaling_rule_model.dart';
import 'package:tm_dashboard/models/session_model.dart';
import 'package:tm_dashboard/models/stop_loss_placement_reason_model.dart';
import 'package:tm_dashboard/models/strategy_tag_model.dart';
import 'package:tm_dashboard/models/take_profit_placement_reason_model.dart';
import 'package:tm_dashboard/models/trade_direction_model.dart';
import 'package:tm_dashboard/models/trade_update_model.dart';
import 'package:tm_dashboard/models/volatility_model.dart';

import 'entry_confirmation_model.dart';
import 'entry_reason_model.dart';
import 'entry_type_model.dart';
import 'entry_zone_type_model.dart';
import 'exit_reason_model.dart';
import 'invalidation_condition_model.dart';
import 'market_bias_model.dart';
import 'market_state_model.dart';
import 'mistake_tag_model.dart';
import 'score_model.dart';

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
  List<ScoreModel> scoreList;
  List<MistakeTagModel> mistakeTags;
  List<StopLossPlacementReasonModel> stopLossPlacementReasons;
  List<TakeProfitPlacementReasonModel> takeProfitPlacementReasons;
  List<EntryTypeModel> entryTypes;
  List<SessionModel> sessions;
  List<StrategyTagModel> strategyTags;
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
    required this.scoreList,
    required this.mistakeTags,
    required this.stopLossPlacementReasons,
    required this.takeProfitPlacementReasons,
    required this.entryTypes,
    required this.sessions,
    required this.strategyTags,
    required this.tradeUpdates,
    required this.exitReasons,
  });

  factory StaticDataResponse.fromJson(Map<String, dynamic> json) {
    List<TradeDirectionModel> tradeDirections = [];
    if (json['tradeDirections'] != null) {
      tradeDirections = (json['tradeDirections'] as List<dynamic>)
          .map((e) => TradeDirectionModel.fromJson(e))
          .toList();
    }

    List<MarketBiasModel> marketBiases = [];
    if (json['marketBiases'] != null) {
      marketBiases = (json['marketBiases'] as List<dynamic>)
          .map((e) => MarketBiasModel.fromJson(e))
          .toList();
    }

    List<MarketStateModel> marketStates = [];
    if (json['marketStates'] != null) {
      marketStates = (json['marketStates'] as List<dynamic>)
          .map((e) => MarketStateModel.fromJson(e))
          .toList();
    }

    List<EntryReasonModel> entryReasons = [];
    if (json['entryReasons'] != null) {
      entryReasons = (json['entryReasons'] as List<dynamic>)
          .map((e) => EntryReasonModel.fromJson(e))
          .toList();
    }

    List<EntryConfirmationModel> entryConfirmations = [];
    if (json['entryConfirmations'] != null) {
      entryConfirmations = (json['entryConfirmations'] as List<dynamic>)
          .map((e) => EntryConfirmationModel.fromJson(e))
          .toList();
    }

    List<EntryZoneTypeModel> entryZoneTypes = [];
    if (json['entryZoneTypes'] != null) {
      entryZoneTypes = (json['entryZoneTypes'] as List<dynamic>)
          .map((e) => EntryZoneTypeModel.fromJson(e))
          .toList();
    }

    List<InvalidationConditionModel> invalidationConditions = [];
    if (json['invalidationConditions'] != null) {
      invalidationConditions = (json['invalidationConditions'] as List<dynamic>)
          .map((e) => InvalidationConditionModel.fromJson(e))
          .toList();
    }

    List<ProbabilityModel> probabilities = [];
    if (json['probabilities'] != null) {
      probabilities = (json['probabilities'] as List<dynamic>)
          .map((e) => ProbabilityModel.fromJson(e))
          .toList();
    }

    List<VolatilityModel> volatilities = [];
    if (json['volatilities'] != null) {
      volatilities = (json['volatilities'] as List<dynamic>)
          .map((e) => VolatilityModel.fromJson(e))
          .toList();
    }

    List<ScalingRuleModel> scalingRules = [];
    if (json['scalingRules'] != null) {
      scalingRules = (json['scalingRules'] as List<dynamic>)
          .map((e) => ScalingRuleModel.fromJson(e))
          .toList();
    }

    List<ScoreModel> scoreList = [];
    if (json['scoreList'] != null) {
      scoreList = (json['scoreList'] as List<dynamic>)
          .map((e) => ScoreModel.fromJson(e))
          .toList();
    }

    List<MistakeTagModel> mistakeTags = [];
    if (json['mistakeTags'] != null) {
      mistakeTags = (json['mistakeTags'] as List<dynamic>)
          .map((e) => MistakeTagModel.fromJson(e))
          .toList();
    }

    List<StopLossPlacementReasonModel> stopLossPlacementReasons = [];
    if (json['stopLossPlacementReasons'] != null) {
      stopLossPlacementReasons =
          (json['stopLossPlacementReasons'] as List<dynamic>)
              .map((e) => StopLossPlacementReasonModel.fromJson(e))
              .toList();
    }

    List<TakeProfitPlacementReasonModel> takeProfitPlacementReasons = [];
    if (json['takeProfitPlacementReasons'] != null) {
      takeProfitPlacementReasons =
          (json['takeProfitPlacementReasons'] as List<dynamic>)
              .map((e) => TakeProfitPlacementReasonModel.fromJson(e))
              .toList();
    }

    List<EntryTypeModel> entryTypes = [];
    if (json['entryTypes'] != null) {
      entryTypes = (json['entryTypes'] as List<dynamic>)
          .map((e) => EntryTypeModel.fromJson(e))
          .toList();
    }

    List<SessionModel> sessions = [];
    if (json['sessions'] != null) {
      sessions = (json['sessions'] as List<dynamic>)
          .map((e) => SessionModel.fromJson(e))
          .toList();
    }

    List<StrategyTagModel> tradeTags = [];
    if (json['strategyTags'] != null) {
      tradeTags = (json['strategyTags'] as List<dynamic>)
          .map((e) => StrategyTagModel.fromJson(e))
          .toList();
    }

    List<TradeUpdateModel> tradeUpdates = [];
    if (json['tradeUpdates'] != null) {
      tradeUpdates = (json['tradeUpdates'] as List<dynamic>)
          .map((e) => TradeUpdateModel.fromJson(e))
          .toList();
    }

    List<ExitReasonModel> exitReasons = [];
    if (json['exitReasons'] != null) {
      exitReasons = (json['exitReasons'] as List<dynamic>)
          .map((e) => ExitReasonModel.fromJson(e))
          .toList();
    }

    return StaticDataResponse(
      tradeDirections: tradeDirections,
      marketBiases: marketBiases,
      marketStates: marketStates,
      entryReasons: entryReasons,
      entryConfirmations: entryConfirmations,
      entryZoneTypes: entryZoneTypes,
      invalidationConditions: invalidationConditions,
      probabilities: probabilities,
      volatilities: volatilities,
      scalingRules: scalingRules,
      scoreList: scoreList,
      mistakeTags: mistakeTags,
      stopLossPlacementReasons: stopLossPlacementReasons,
      takeProfitPlacementReasons: takeProfitPlacementReasons,
      entryTypes: entryTypes,
      sessions: sessions,
      strategyTags: tradeTags,
      tradeUpdates: tradeUpdates,
      exitReasons: exitReasons,
    );
  }
}
