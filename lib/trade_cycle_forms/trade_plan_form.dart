import 'package:flutter/material.dart';
import 'package:tm_dashboard/enums/entry_confirmation_enum.dart';
import 'package:tm_dashboard/enums/entry_reason_enum.dart';
import 'package:tm_dashboard/enums/entry_zone_type_enum.dart';
import 'package:tm_dashboard/enums/invalidation_condition_enum.dart';
import 'package:tm_dashboard/enums/market_bias_enum.dart';
import 'package:tm_dashboard/enums/market_state_enum.dart';
import 'package:tm_dashboard/enums/probability_enum.dart';
import 'package:tm_dashboard/enums/scaling_rule_enum.dart';
import 'package:tm_dashboard/enums/score_enum.dart';
import 'package:tm_dashboard/enums/stop_loss_placement_reason_enum.dart';
import 'package:tm_dashboard/enums/take_profit_placement_reason.dart';
import 'package:tm_dashboard/enums/trade_direction_enum.dart';
import 'package:tm_dashboard/enums/volatility_enum.dart';
import 'package:tm_dashboard/services/trade_calculator_service.dart';
import 'package:tm_dashboard/widgets/form_multi_select.dart';

import '../models/static_data.dart';
import '../services/data_service.dart';
import '../widgets/form_dropdown.dart';
import '../widgets/form_number_field.dart';
import '../widgets/form_text_area_field.dart';
import '../widgets/section_card.dart';

class TradePlanForm extends StatefulWidget {
  const TradePlanForm({super.key});

  @override
  State<TradePlanForm> createState() => _TradePlanFormState();
}

class _TradePlanFormState extends State<TradePlanForm> {
  final DataService _dataService = DataService();
  final _formKey = GlobalKey<FormState>();

  // State Variables
  TradeDirectionEnum? direction;
  MarketBiasEnum? marketBias;
  MarketStateEnum? marketState;
  VolatilityEnum? volatility;
  List<EntryReasonEnum> entryReasons = [];
  List<EntryConfirmationEnum> entryConfirmations = [];
  EntryZoneTypeEnum? entryZoneType;
  StaticDataResponse? data;
  InvalidationConditionEnum? invalidationCondition;
  bool willPyramid = false;
  bool willBoost = false;
  List<ScalingRuleEnum> scalingRules = [];
  List<int> boostRules = [];
  ScoreEnum? focusLevel;
  ScoreEnum? stressLevel;
  ScoreEnum? confidenceLevel;
  ProbabilityEnum? probability;
  StopLossPlacementReasonEnum? slLogic;
  TakeProfitPlacementReasonEnum? tpLogic;

  // Controllers
  final entryZoneStartCtrl = TextEditingController();
  final entryZoneEndCtrl = TextEditingController();
  final estimatedEntryCtrl = TextEditingController();
  final invalidationStartCtrl = TextEditingController();
  final invalidationEndCtrl = TextEditingController();
  final lotSizeCtrl = TextEditingController();
  final rrCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final slCtrl = TextEditingController();
  final slPipsCtrl = TextEditingController();
  final slUsdCtrl = TextEditingController();
  final tpCtrl = TextEditingController();
  final tpPipsCtrl = TextEditingController();
  final tpUsdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();

    slCtrl.addListener(_recalculateStopLoss);
    tpCtrl.addListener(_recalculateTakeProfit);
    estimatedEntryCtrl.addListener(_recalculateStopLoss);
    estimatedEntryCtrl.addListener(_recalculateTakeProfit);
    lotSizeCtrl.addListener(_recalculateStopLoss);
    lotSizeCtrl.addListener(_recalculateTakeProfit);
  }

  @override
  void dispose() {
    entryZoneStartCtrl.dispose();
    entryZoneEndCtrl.dispose();
    estimatedEntryCtrl.dispose();
    invalidationStartCtrl.dispose();
    invalidationEndCtrl.dispose();
    lotSizeCtrl.dispose();
    rrCtrl.dispose();
    notesCtrl.dispose();
    slCtrl.dispose();
    slPipsCtrl.dispose();
    slUsdCtrl.dispose();
    tpCtrl.dispose();
    tpPipsCtrl.dispose();
    tpUsdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final tempData = await _dataService.getAll();
    setState(() {
      data = tempData;
    });
  }

  void _recalculateStopLoss() {
    final entry = double.tryParse(estimatedEntryCtrl.text);
    final sl = double.tryParse(slCtrl.text);
    final lotSize = double.tryParse(lotSizeCtrl.text);

    if (entry == null || sl == null || lotSize == null || direction == null) {
      slPipsCtrl.text = '';
      slUsdCtrl.text = '';
      return;
    }

    final priceDiff = TradeCalculatorService.calculatePriceDifference(
      direction: direction!,
      entry: entry,
      target: sl,
    );

    if (priceDiff == null || priceDiff >= 0) {
      slPipsCtrl.text = '';
      slUsdCtrl.text = '';
      return;
    }

    // For Stop Loss, we want the absolute difference for USD/Pips
    final absDiff = priceDiff.abs();
    slPipsCtrl.text = TradeCalculatorService.calculatePips(absDiff).toStringAsFixed(1);
    slUsdCtrl.text =
        TradeCalculatorService.calculateUsd(absDiff, lotSize).toStringAsFixed(2);

    _recalculateRR();
  }

  void _recalculateTakeProfit() {
    final entry = double.tryParse(estimatedEntryCtrl.text);
    final tp = double.tryParse(tpCtrl.text);
    final lotSize = double.tryParse(lotSizeCtrl.text);

    if (entry == null || tp == null || lotSize == null || direction == null) {
      tpPipsCtrl.text = '';
      tpUsdCtrl.text = '';
      return;
    }

    final priceDiff = TradeCalculatorService.calculatePriceDifference(
      direction: direction!,
      entry: entry,
      target: tp,
    );

    if (priceDiff == null || priceDiff <= 0) {
      tpPipsCtrl.text = '';
      tpUsdCtrl.text = '';
      return;
    }

    tpPipsCtrl.text =
        TradeCalculatorService.calculatePips(priceDiff).toStringAsFixed(1);
    tpUsdCtrl.text =
        TradeCalculatorService.calculateUsd(priceDiff, lotSize).toStringAsFixed(2);

    _recalculateRR();
  }

  void _recalculateRR() {
    final slUsd = double.tryParse(slUsdCtrl.text);
    final tpUsd = double.tryParse(tpUsdCtrl.text);

    final rr = TradeCalculatorService.calculateRR(slUsd, tpUsd);
    rrCtrl.text = rr?.toStringAsFixed(2) ?? '';
  }

  void _submitForm() {
    final sentData = {
      "direction": direction,
      "marketBias": marketBias,
      "marketState": marketState,
      "volatilityExpectation": volatility,
      "entryReasons": entryReasons,
      "entryConfirmations": entryConfirmations,
      "entryZoneType": entryZoneType,
      "entryZoneStartLevel": entryZoneStartCtrl.text,
      "entryZoneEndLevel": entryZoneEndCtrl.text,
      "estimatedEntryLevel": estimatedEntryCtrl.text,
      "invalidationStartLevel": invalidationStartCtrl.text,
      "invalidationEndLevel": invalidationEndCtrl.text,
      "invalidationCondition": invalidationCondition,
      "willPyramid": willPyramid,
      "scalingRules": scalingRules,
      "willBoost": willBoost,
      "boostRules": boostRules,
      "lotSize": lotSizeCtrl.text,
      "riskRewardRatio": rrCtrl.text,
      "stopLossPrice": slCtrl.text,
      "stopLossInPips": slPipsCtrl.text,
      "stopLossInUSD": slUsdCtrl.text,
      "stopLossPlacementLogic": slLogic,
      "takeProfitPrice": tpCtrl.text,
      "takeProfitInPips": tpPipsCtrl.text,
      "takeProfitInUSD": tpUsdCtrl.text,
      "takeProfitPlacementLogic": tpLogic,
      "focusLevel": focusLevel,
      "stressLevel": stressLevel,
      "confidenceLevel": confidenceLevel,
      "expectedProbabilityOfSuccess": probability,
      "notes": notesCtrl.text,
    };

    debugPrint("sentData: $sentData");
  }

  Color? _getRRFillColor() {
    final value = double.tryParse(rrCtrl.text);
    if (value == null) return null;

    if (value < 1.0) return Colors.red.withOpacity(0.1);
    if (value < 1.5) return Colors.orange.withOpacity(0.1);
    return Colors.green.withOpacity(0.1);
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMarketDirectionSection(),
            _buildEntryLogicSection(),
            _buildPositionManagementSection(),
            _buildRiskExpectancySection(),
            _buildStopLossSection(),
            _buildTakeProfitSection(),
            _buildPsychologicalSection(),
            _buildTradeQualitySection(),
            _buildAdditionalDetailsSection(),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketDirectionSection() {
    return SectionCard(
      title: "Market Direction",
      icon: Icons.trending_up,
      children: [
        FormDropdown<TradeDirectionEnum>(
          label: "Direction",
          items: TradeDirectionEnum.values,
          value: direction,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => direction = v),
        ),
        FormDropdown<MarketBiasEnum>(
          label: "Market Bias",
          items: MarketBiasEnum.values,
          value: marketBias,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => marketBias = v),
        ),
        FormDropdown<MarketStateEnum>(
          label: "Market State",
          items: MarketStateEnum.values,
          value: marketState,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => marketState = v),
        ),
        FormDropdown<VolatilityEnum>(
          label: "Volatility",
          items: VolatilityEnum.values,
          value: volatility,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => volatility = v),
        ),
      ],
    );
  }

  Widget _buildEntryLogicSection() {
    return SectionCard(
      title: "Entry Logic",
      icon: Icons.login,
      children: [
        FormMultiSelect<EntryReasonEnum>(
          title: "Entry Reasons",
          options: EntryReasonEnum.values,
          selected: entryReasons,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => entryReasons = v),
        ),
        FormMultiSelect<EntryConfirmationEnum>(
          title: "Confirmations",
          options: EntryConfirmationEnum.values,
          selected: entryConfirmations,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => entryConfirmations = v),
        ),
        FormDropdown<EntryZoneTypeEnum>(
          label: "Entry Zone Type",
          items: EntryZoneTypeEnum.values,
          value: entryZoneType,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => entryZoneType = v),
        ),
        Row(
          children: [
            Expanded(
              child: FormNumberField(
                  label: "Zone Start", controller: entryZoneStartCtrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FormNumberField(
                  label: "Zone End", controller: entryZoneEndCtrl),
            ),
          ],
        ),
        FormNumberField(label: "Estimated Entry", controller: estimatedEntryCtrl),
        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: "Invalidation Start",
                controller: invalidationStartCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FormNumberField(
                label: "Invalidation End",
                controller: invalidationEndCtrl,
              ),
            ),
          ],
        ),
        FormDropdown<InvalidationConditionEnum>(
          label: "Invalidation Condition",
          items: InvalidationConditionEnum.values,
          value: invalidationCondition,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => invalidationCondition = v),
        ),
      ],
    );
  }

  Widget _buildPositionManagementSection() {
    return SectionCard(
      title: "Position Management",
      icon: Icons.layers,
      children: [
        SwitchListTile.adaptive(
          title: const Text("Enable pyramiding"),
          value: willPyramid,
          onChanged: (v) => setState(() => willPyramid = v),
        ),
        if (willPyramid)
          FormMultiSelect<ScalingRuleEnum>(
            title: "Scaling Rules",
            options: ScalingRuleEnum.values,
            selected: scalingRules,
            labelBuilder: (e) => e.name,
            onChanged: (v) => setState(() => scalingRules = v),
          ),
        SwitchListTile.adaptive(
          title: const Text("Enable boost"),
          value: willBoost,
          onChanged: (v) => setState(() => willBoost = v),
        ),
      ],
    );
  }

  Widget _buildRiskExpectancySection() {
    return SectionCard(
      title: "Risk & Expectancy",
      icon: Icons.shield,
      children: [
        Row(
          children: [
            Expanded(
                child: FormNumberField(label: "Lot Size", controller: lotSizeCtrl)),
            const SizedBox(width: 12),
            Expanded(
              child: FormNumberField(
                label: "R:R",
                controller: rrCtrl,
                readOnly: true,
                fillColor: _getRRFillColor(),
              ),
            ),
          ],
        ),
        FormDropdown<ProbabilityEnum>(
          label: "Expected Probability",
          items: ProbabilityEnum.values,
          value: probability,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => probability = v),
        ),
      ],
    );
  }

  Widget _buildStopLossSection() {
    return SectionCard(
      title: "Stop Loss Details",
      icon: Icons.stop_circle,
      children: [
        FormNumberField(label: "Stop Loss Price", controller: slCtrl),
        FormDropdown<StopLossPlacementReasonEnum>(
          label: "Stop Loss Logic",
          items: StopLossPlacementReasonEnum.values,
          value: slLogic,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => slLogic = v),
        ),
        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: "Stop Loss (Pips)",
                controller: slPipsCtrl,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FormNumberField(
                label: "Stop Loss (USD)",
                controller: slUsdCtrl,
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTakeProfitSection() {
    return SectionCard(
      title: "Take Profit Details",
      icon: Icons.rocket,
      children: [
        FormNumberField(label: "Take Profit Price", controller: tpCtrl),
        FormDropdown<TakeProfitPlacementReasonEnum>(
          label: "Take Profit Logic",
          items: TakeProfitPlacementReasonEnum.values,
          value: tpLogic,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => tpLogic = v),
        ),
        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: "Take Profit (Pips)",
                controller: tpPipsCtrl,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FormNumberField(
                label: "Take Profit (USD)",
                controller: tpUsdCtrl,
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPsychologicalSection() {
    return SectionCard(
      title: "Psychological Factors",
      icon: Icons.rate_review,
      children: [
        FormDropdown<ScoreEnum>(
          label: "Focus Level",
          items: ScoreEnum.values,
          value: focusLevel,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => focusLevel = v),
        ),
        FormDropdown<ScoreEnum>(
          label: "Stress Level",
          items: ScoreEnum.values,
          value: stressLevel,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => stressLevel = v),
        ),
        FormDropdown<ScoreEnum>(
          label: "Confidence Level",
          items: ScoreEnum.values,
          value: confidenceLevel,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => confidenceLevel = v),
        ),
      ],
    );
  }

  Widget _buildTradeQualitySection() {
    return SectionCard(
      title: "Trade Quality and Performance",
      icon: Icons.high_quality,
      children: [
        FormDropdown<ProbabilityEnum>(
          label: "Expected Probability of Success",
          items: ProbabilityEnum.values,
          value: probability,
          labelBuilder: (e) => e.name,
          onChanged: (v) => setState(() => probability = v),
        ),
      ],
    );
  }

  Widget _buildAdditionalDetailsSection() {
    return SectionCard(
      title: "Additional Details",
      icon: Icons.note,
      children: [FormTextAreaField(label: "Notes", controller: notesCtrl)],
    );
  }

  Widget _buildSubmitButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.check_circle_outline),
        label: const Text("Submit"),
        onPressed: _submitForm,
      ),
    );
  }
}
