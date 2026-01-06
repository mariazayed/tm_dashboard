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

import '../models/static_data.dart';
import '../services/data_service.dart';

class MarketContextForm extends StatefulWidget {
  const MarketContextForm({super.key});

  @override
  State<MarketContextForm> createState() => _MarketContextFormState();
}

class _MarketContextFormState extends State<MarketContextForm> {
  @override
  void initState() {
    super.initState();
    loadData();

    slCtrl.addListener(_recalculateStopLoss);
    tpCtrl.addListener(_recalculateTakeProfit);

    estimatedEntryCtrl.addListener(_recalculateStopLoss);
    estimatedEntryCtrl.addListener(_recalculateTakeProfit);

    lotSizeCtrl.addListener(_recalculateStopLoss);
    lotSizeCtrl.addListener(_recalculateTakeProfit);
  }

  @override
  void dispose() {
    slCtrl.dispose();
    slPipsCtrl.dispose();
    slUsdCtrl.dispose();

    tpCtrl.dispose();
    tpPipsCtrl.dispose();
    tpUsdCtrl.dispose();

    rrCtrl.dispose();

    super.dispose();
  }

  final DataService _dataService = DataService();

  final _formKey = GlobalKey<FormState>();

  TradeDirectionEnum? direction;

  MarketBiasEnum? marketBias;

  MarketStateEnum? marketState;

  VolatilityEnum? volatility;

  List<EntryReasonEnum> entryReasons = [];

  List<EntryConfirmationEnum> entryConfirmations = [];

  EntryZoneTypeEnum? entryZoneType;

  StaticDataResponse? data;

  final entryZoneStartCtrl = TextEditingController();

  final entryZoneEndCtrl = TextEditingController();

  final estimatedEntryCtrl = TextEditingController();

  final invalidationStartCtrl = TextEditingController();

  final invalidationEndCtrl = TextEditingController();

  InvalidationConditionEnum? invalidationCondition;

  bool willPyramid = false;

  bool willBoost = false;

  List<ScalingRuleEnum> scalingRules = [];

  List<int> boostRules = [];

  final lotSizeCtrl = TextEditingController();

  final rrCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  final slCtrl = TextEditingController();
  final slPipsCtrl = TextEditingController();
  final slUsdCtrl = TextEditingController();

  final tpCtrl = TextEditingController();
  final tpPipsCtrl = TextEditingController();
  final tpUsdCtrl = TextEditingController();

  ScoreEnum? focusLevel;

  ScoreEnum? stressLevel;

  ScoreEnum? confidenceLevel;

  ProbabilityEnum? probability;
  StopLossPlacementReasonEnum? slLogic;
  TakeProfitPlacementReasonEnum? tpLogic;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const CircularProgressIndicator();
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          sectionCard(
            title: "Market Direction",
            icon: Icons.trending_up,
            children: [
              _dropdown<TradeDirectionEnum>(
                "Direction",
                TradeDirectionEnum.values,
                direction,
                (TradeDirectionEnum e) => e.name,
                (TradeDirectionEnum? v) {
                  setState(() {
                    direction = v;
                  });
                },
              ),
              _dropdown<MarketBiasEnum>(
                "Market Bias",
                MarketBiasEnum.values,
                marketBias,
                (MarketBiasEnum e) => e.name,
                (MarketBiasEnum? v) => setState(() => marketBias = v),
              ),
              _dropdown<MarketStateEnum>(
                "Market State",
                MarketStateEnum.values,
                marketState,
                (MarketStateEnum e) => e.name,
                (MarketStateEnum? v) => setState(() => marketState = v),
              ),
              _dropdown<VolatilityEnum>(
                "Volatility",
                VolatilityEnum.values,
                volatility,
                (VolatilityEnum e) => e.name,
                (VolatilityEnum? v) => setState(() => volatility = v),
              ),
            ],
          ),

          sectionCard(
            title: "Entry Logic",
            icon: Icons.login,
            children: [
              _multiSelect<EntryReasonEnum>(
                title: "Entry Reasons",
                options: EntryReasonEnum.values,
                selected: entryReasons,
                labelBuilder: (e) => e.name,
                onChanged: (v) => setState(() => entryReasons = v),
              ),

              _multiSelect<EntryConfirmationEnum>(
                title: "Confirmations",
                options: EntryConfirmationEnum.values,
                selected: entryConfirmations,
                labelBuilder: (e) => e.name,
                onChanged: (v) => setState(() => entryConfirmations = v),
              ),

              _dropdown<EntryZoneTypeEnum>(
                "Entry Zone Type",
                EntryZoneTypeEnum.values,
                entryZoneType,
                (EntryZoneTypeEnum e) => e.name,
                (EntryZoneTypeEnum? v) => setState(() => entryZoneType = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: _numberField("Zone Start", entryZoneStartCtrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField("Zone End", entryZoneEndCtrl)),
                ],
              ),

              _numberField("Estimated Entry", estimatedEntryCtrl),

              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      "Invalidation Start",
                      invalidationStartCtrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(
                      "Invalidation End",
                      invalidationEndCtrl,
                    ),
                  ),
                ],
              ),

              _dropdown<InvalidationConditionEnum>(
                "Invalidation Condition",
                InvalidationConditionEnum.values,
                invalidationCondition,
                (InvalidationConditionEnum e) => e.name,
                (InvalidationConditionEnum? v) =>
                    setState(() => invalidationCondition = v),
              ),
            ],
          ),

          sectionCard(
            title: "Position Management",
            icon: Icons.layers,
            children: [
              SwitchListTile.adaptive(
                title: const Text("Enable pyramiding"),
                value: willPyramid,
                onChanged: (v) => setState(() => willPyramid = v),
              ),

              if (willPyramid)
                _multiSelect<ScalingRuleEnum>(
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

              // if (willBoost)
              //   _multiSelect("Boost Rules", data!.boostRules, boostRules),
            ],
          ),

          sectionCard(
            title: "Risk & Expectancy",
            icon: Icons.shield,
            children: [
              Row(
                children: [
                  Expanded(child: _numberField("Lot Size", lotSizeCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField("R:R", rrCtrl, readOnly: true)),
                ],
              ),
              _dropdown<ProbabilityEnum>(
                "Expected Probability",
                ProbabilityEnum.values,
                probability,
                (ProbabilityEnum e) => e.name,
                (ProbabilityEnum? v) => setState(() => probability = v),
              ),
            ],
          ),

          sectionCard(
            title: "Stop Loss Details",
            icon: Icons.stop_circle,
            children: [
              _numberField("Stop Loss Price", slCtrl),
              _dropdown<StopLossPlacementReasonEnum>(
                "Stop Loss Logic",
                StopLossPlacementReasonEnum.values,
                slLogic,
                (StopLossPlacementReasonEnum e) => e.name,
                (StopLossPlacementReasonEnum? v) => setState(() => slLogic = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      "Stop Loss (Pips)",
                      slPipsCtrl,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(
                      "Stop Loss (USD)",
                      slUsdCtrl,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
            ],
          ),

          sectionCard(
            title: "Take Profit Details",
            icon: Icons.rocket,
            children: [
              _numberField("Take Profit Price", tpCtrl),
              _dropdown<TakeProfitPlacementReasonEnum>(
                "Take Profit Logic",
                TakeProfitPlacementReasonEnum.values,
                tpLogic,
                (TakeProfitPlacementReasonEnum e) => e.name,
                (TakeProfitPlacementReasonEnum? v) =>
                    setState(() => tpLogic = v),
              ),
              Row(
                children: [
                  Expanded(
                    child: _numberField(
                      "Take Profit (Pips)",
                      tpPipsCtrl,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(
                      "Take Profit (USD)",
                      tpUsdCtrl,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          sectionCard(
            title: "Psychological Factors",
            icon: Icons.rate_review,
            children: [
              _dropdown<ScoreEnum>(
                "Focus Level",
                ScoreEnum.values,
                focusLevel,
                (ScoreEnum e) => e.name,
                (ScoreEnum? v) => setState(() => focusLevel = v),
              ),
              _dropdown<ScoreEnum>(
                "Stress Level",
                ScoreEnum.values,
                stressLevel,
                (ScoreEnum e) => e.name,
                (ScoreEnum? v) => setState(() => stressLevel = v),
              ),
              _dropdown<ScoreEnum>(
                "Confidence Level",
                ScoreEnum.values,
                confidenceLevel,
                (ScoreEnum e) => e.name,
                (ScoreEnum? v) => setState(() => confidenceLevel = v),
              ),
            ],
          ),
          sectionCard(
            title: "Trade Quality and Performance",
            icon: Icons.high_quality,
            children: [
              _dropdown<ProbabilityEnum>(
                "Expected Probability of Success",
                ProbabilityEnum.values,
                probability,
                (ProbabilityEnum e) => e.name,
                (ProbabilityEnum? v) => setState(() => probability = v),
              ),
            ],
          ),
          sectionCard(
            title: "Additional Details",
            icon: Icons.note,
            children: [_textAreaField("Notes", notesCtrl)],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Submit"),
              onPressed: _submitForm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>(
    String label,
    List<T> items,
    T? value,
    String Function(T) labelBuilder,
    ValueChanged<T?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map(
              (e) =>
                  DropdownMenuItem<T>(value: e, child: Text(labelBuilder(e))),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _numberField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    final value = double.tryParse(controller.text);

    Color? fillColor;
    if (readOnly && value != null && label == "R:R") {
      if (value < 1.0) {
        fillColor = Colors.red.withOpacity(0.1);
      } else if (value < 1.5)
        fillColor = Colors.orange.withOpacity(0.1);
      else
        fillColor = Colors.green.withOpacity(0.1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: fillColor != null,
          fillColor: fillColor,
        ),
      ),
    );
  }

  Widget _textAreaField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        minLines: 1,
        maxLines: 5,
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _multiSelect<T>({
    required String title,
    required List<T> options,
    required List<T> selected,
    required String Function(T) labelBuilder,
    required void Function(List<T>) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: options.map((o) {
              final isSelected = selected.contains(o);

              return FilterChip(
                label: Text(labelBuilder(o)),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (v) {
                  final updated = List<T>.from(selected);

                  v ? updated.add(o) : updated.remove(o);
                  onChanged(updated);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget sectionCard({
    required String title,
    IconData? icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) Icon(icon, size: 20, color: Colors.blueGrey),
                if (icon != null) const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> loadData() async {
    final tempData = await _dataService.getAll();

    setState(() {
      data = tempData;
    });
  }

  void _submitForm() {
    // 1️⃣ Validate text fields
    // if (!_formKey.currentState!.validate()) {
    //   return;
    // }
    //
    // // 2️⃣ Validate required enums
    // if (direction == null ||
    //     marketBias == null ||
    //     marketState == null ||
    //     volatility == null ||
    //     probability == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text("Please complete all required selections."),
    //     ),
    //   );
    //   return;
    // }
    //
    // // 3️⃣ Validate multi-selects if needed
    // if (entryReasons.isEmpty || entryConfirmations.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text(
    //         "Please select at least one entry reason and confirmation.",
    //       ),
    //     ),
    //   );
    //   return;
    // }

    // 4️⃣ Submit (API integration later)
    // debugPrint("Trade form submitted successfully");

    dynamic sentData = {
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

    // Example payload (safe & typed)
    debugPrint("""
sentData: $sentData
""");

    // 5️⃣ Close dialog (optional)
    // Navigator.of(context).pop();
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

    final priceDiff = direction == TradeDirectionEnum.LONG
        ? entry - sl
        : sl - entry;

    if (priceDiff <= 0) {
      slPipsCtrl.text = '';
      slUsdCtrl.text = '';
      return;
    }

    final pips = priceDiff * 10;
    final usd = priceDiff * lotSize * 100;

    slPipsCtrl.text = pips.toStringAsFixed(1);
    slUsdCtrl.text = usd.toStringAsFixed(2);

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

    final priceDiff = direction == TradeDirectionEnum.LONG
        ? tp - entry
        : entry - tp;

    if (priceDiff <= 0) {
      tpPipsCtrl.text = '';
      tpUsdCtrl.text = '';
      return;
    }

    final pips = priceDiff * 10;
    final usd = priceDiff * lotSize * 100;

    tpPipsCtrl.text = pips.toStringAsFixed(1);
    tpUsdCtrl.text = usd.toStringAsFixed(2);

    _recalculateRR();
  }

  void _recalculateRR() {
    final slUsd = double.tryParse(slUsdCtrl.text);
    final tpUsd = double.tryParse(tpUsdCtrl.text);

    if (slUsd == null || tpUsd == null || slUsd <= 0) {
      rrCtrl.text = '';
      return;
    }

    final rr = tpUsd / slUsd;
    rrCtrl.text = rr.toStringAsFixed(2);
  }
}
