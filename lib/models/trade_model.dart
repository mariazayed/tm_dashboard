import 'package:tm_dashboard/enums/day_of_week_enum.dart';
import 'package:tm_dashboard/enums/entry_confirmation_enum.dart';
import 'package:tm_dashboard/enums/entry_reason_enum.dart';
import 'package:tm_dashboard/enums/entry_zone_type_enum.dart';
import 'package:tm_dashboard/enums/exit_reason_enum.dart';
import 'package:tm_dashboard/enums/invalidation_condition_enum.dart';
import 'package:tm_dashboard/enums/market_bias_enum.dart';
import 'package:tm_dashboard/enums/market_state_enum.dart';
import 'package:tm_dashboard/enums/mistake_tag_enum.dart';
import 'package:tm_dashboard/enums/probability_enum.dart';
import 'package:tm_dashboard/enums/scaling_rule_enum.dart';
import 'package:tm_dashboard/enums/score_enum.dart';
import 'package:tm_dashboard/enums/session_enum.dart';
import 'package:tm_dashboard/enums/stop_loss_placement_reason_enum.dart';
import 'package:tm_dashboard/enums/take_profit_placement_reason.dart';
import 'package:tm_dashboard/enums/trade_direction_enum.dart';
import 'package:tm_dashboard/enums/trade_source_enum.dart';
import 'package:tm_dashboard/enums/trade_type_enum.dart';
import 'package:tm_dashboard/enums/volatility_enum.dart';
import 'package:tm_dashboard/models/asset_model.dart';
import 'package:tm_dashboard/models/strategy_model.dart';

class Trade {
  // --- Fields already relied on by trade_card.dart, journal_card.dart,
  // trade_journal_screen.dart and classes/trade_journal.dart -- names and
  // types kept exactly as before. ---
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

  // --- Added in Phase 6: every trade needs an id to be addressable via
  // PATCH /trade/{id}/review and POST /trade/{id}/suggest. ---
  final int id;

  // --- Trade management prices (Phase 1-3) ---
  final double? slPrice;
  final double? tpPrice;

  // --- Source & traceability ---
  final String? externalId;
  final TradeSourceEnum? source;
  final DateTime? reviewedAt;

  // --- Setup context ---
  final SessionEnum? session;
  final DayOfWeekEnum? dayOfWeek;
  final VolatilityEnum? volatility;
  final TradeTypeEnum? tradeType;
  final MarketStateEnum? marketState;
  final MarketBiasEnum? marketBias;
  final EntryReasonEnum? entryReason;
  final EntryConfirmationEnum? entryConfirmation;
  final EntryZoneTypeEnum? entryZoneType;
  final ProbabilityEnum? probability;

  // --- Risk & sizing ---
  final double? riskPercent;
  final double? accountBalanceAtEntry;
  final double? plannedRiskReward;
  final double? rMultiple;
  final ScalingRuleEnum? scalingRule;

  // --- Trade management & outcome ---
  final double? mae;
  final double? mfe;
  final ExitReasonEnum? exitReason;
  final InvalidationConditionEnum? invalidationCondition;
  final StopLossPlacementReasonEnum? slPlacementReason;
  final TakeProfitPlacementReasonEnum? tpPlacementReason;

  // --- Discipline & psychology (filled via the review flow, Phase 6) ---
  final bool? followedPlan;
  final ScoreEnum? disciplineScore;
  final List<MistakeTagEnum>? mistakeTags;

  // --- AI-assisted structure detection (Phase 5) ---
  final String? detectedStructures;

  bool get isReviewed => reviewedAt != null;

  static Future<Trade> fromJson(Map<String, dynamic> json) async {
    return Trade(
      id: json['id'],
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
      slPrice: (json['slPrice'] as num?)?.toDouble(),
      tpPrice: (json['tpPrice'] as num?)?.toDouble(),
      externalId: json['externalId'],
      source: json['source'] != null
          ? TradeSourceEnum.fromValue(json['source'])
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      session: json['session'] != null
          ? SessionEnum.fromValue(json['session'])
          : null,
      dayOfWeek: json['dayOfWeek'] != null
          ? DayOfWeekEnum.fromValue(json['dayOfWeek'])
          : null,
      volatility: json['volatility'] != null
          ? VolatilityEnum.fromValue(json['volatility'])
          : null,
      tradeType: json['tradeType'] != null
          ? TradeTypeEnum.fromValue(json['tradeType'])
          : null,
      marketState: json['marketState'] != null
          ? MarketStateEnum.fromValue(json['marketState'])
          : null,
      marketBias: json['marketBias'] != null
          ? MarketBiasEnum.fromValue(json['marketBias'])
          : null,
      entryReason: json['entryReason'] != null
          ? EntryReasonEnum.fromValue(json['entryReason'])
          : null,
      entryConfirmation: json['entryConfirmation'] != null
          ? EntryConfirmationEnum.fromValue(json['entryConfirmation'])
          : null,
      entryZoneType: json['entryZoneType'] != null
          ? EntryZoneTypeEnum.fromValue(json['entryZoneType'])
          : null,
      probability: json['probability'] != null
          ? ProbabilityEnum.fromValue(json['probability'])
          : null,
      riskPercent: (json['riskPercent'] as num?)?.toDouble(),
      accountBalanceAtEntry: (json['accountBalanceAtEntry'] as num?)
          ?.toDouble(),
      plannedRiskReward: (json['plannedRiskReward'] as num?)?.toDouble(),
      rMultiple: (json['rMultiple'] as num?)?.toDouble(),
      scalingRule: json['scalingRule'] != null
          ? ScalingRuleEnum.fromValue(json['scalingRule'])
          : null,
      mae: (json['mae'] as num?)?.toDouble(),
      mfe: (json['mfe'] as num?)?.toDouble(),
      exitReason: json['exitReason'] != null
          ? ExitReasonEnum.fromValue(json['exitReason'])
          : null,
      invalidationCondition: json['invalidationCondition'] != null
          ? InvalidationConditionEnum.fromValue(json['invalidationCondition'])
          : null,
      slPlacementReason: json['slPlacementReason'] != null
          ? StopLossPlacementReasonEnum.fromValue(json['slPlacementReason'])
          : null,
      tpPlacementReason: json['tpPlacementReason'] != null
          ? TakeProfitPlacementReasonEnum.fromValue(json['tpPlacementReason'])
          : null,
      followedPlan: json['followedPlan'],
      disciplineScore: json['disciplineScore'] != null
          ? ScoreEnum.fromValue(json['disciplineScore'])
          : null,
      mistakeTags: json['mistakeTags'] != null
          ? (json['mistakeTags'] as List<dynamic>)
              .map((e) => MistakeTagEnum.fromValue(e as int))
              .toList()
          : null,
      detectedStructures: json['detectedStructures'],
    );
  }

  Trade({
    required this.id,
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
    this.slPrice,
    this.tpPrice,
    this.externalId,
    this.source,
    this.reviewedAt,
    this.session,
    this.dayOfWeek,
    this.volatility,
    this.tradeType,
    this.marketState,
    this.marketBias,
    this.entryReason,
    this.entryConfirmation,
    this.entryZoneType,
    this.probability,
    this.riskPercent,
    this.accountBalanceAtEntry,
    this.plannedRiskReward,
    this.rMultiple,
    this.scalingRule,
    this.mae,
    this.mfe,
    this.exitReason,
    this.invalidationCondition,
    this.slPlacementReason,
    this.tpPlacementReason,
    this.followedPlan,
    this.disciplineScore,
    this.mistakeTags,
    this.detectedStructures,
  });
}
