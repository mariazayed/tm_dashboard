import 'package:flutter/material.dart';
import 'package:tm_dashboard/enums/entry_confirmation_enum.dart';
import 'package:tm_dashboard/enums/entry_reason_enum.dart';
import 'package:tm_dashboard/enums/entry_zone_type_enum.dart';
import 'package:tm_dashboard/enums/invalidation_condition_enum.dart';
import 'package:tm_dashboard/enums/market_bias_enum.dart';
import 'package:tm_dashboard/enums/market_state_enum.dart';
import 'package:tm_dashboard/enums/probability_enum.dart';
import 'package:tm_dashboard/enums/scaling_rule_enum.dart';
import 'package:tm_dashboard/enums/trade_direction_enum.dart';
import 'package:tm_dashboard/enums/volatility_enum.dart';
import 'package:tm_dashboard/services/day_service.dart';

import '../../../bloc/calendar_state.dart';
import '../../../models/day_model.dart';
import '../../../models/static_data.dart';
import '../../../services/data_service.dart';

class DayEditDialog extends StatefulWidget {
  final DayModel day;
  final CalendarCubit cubit;

  const DayEditDialog({super.key, required this.day, required this.cubit});

  @override
  State<DayEditDialog> createState() => _DayEditDialogState();
}

class _DayEditDialogState extends State<DayEditDialog> {
  final DayService _dayService = DayService();
  final DataService _dataService = DataService();

  final _formKey = GlobalKey<FormState>();

  /// ---------------- STEP STATE ----------------
  int _currentStep = 0;

  /// ---------------- DAY FLAGS (ORIGINAL) ----------------
  late bool weekend;
  late bool noWork;
  late bool ended;

  /// ---------------- STEP 1 – MARKET CONTEXT ----------------
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

  int? focusLevel;
  int? stressLevel;
  int? confidenceLevel;
  ProbabilityEnum? probability;

  @override
  void initState() {
    super.initState();
    weekend = widget.day.weekend;
    noWork = widget.day.noWork;
    ended = widget.day.ended;

    loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const CircularProgressIndicator();
    }

    return AlertDialog(
      title: Text("Day ${widget.day.date.day}"),
      content: SizedBox(
        width: 950,
        height: 700,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ================= DAY CHECKBOXES =================
              Wrap(
                spacing: 12,
                children: [
                  FilterChip(
                    label: const Text("Weekend"),
                    selected: weekend,
                    onSelected: (v) => setState(() => weekend = v),
                  ),
                  FilterChip(
                    label: const Text("No Work"),
                    selected: noWork,
                    onSelected: (v) => setState(() => noWork = v),
                  ),
                  FilterChip(
                    label: const Text("Ended"),
                    selected: ended,
                    onSelected: (v) => setState(() => ended = v),
                  ),
                ],
              ),

              const Divider(height: 32),

              /// ================= STEPPER FORM =================
              Text(
                "Trade Planning",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 500,
                child: Stepper(
                  currentStep: _currentStep,
                  type: StepperType.horizontal,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  onStepContinue: () {
                    if (_currentStep < 4) {
                      setState(() => _currentStep++);
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep--);
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Row(
                      children: [
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: const Text("Next"),
                        ),
                        const SizedBox(width: 12),
                        if (_currentStep > 0)
                          OutlinedButton(
                            onPressed: details.onStepCancel,
                            child: const Text("Back"),
                          ),
                      ],
                    );
                  },
                  steps: [
                    _marketContextStep(),
                    _emptyStep("Trade Management"),
                    _emptyStep("Execution"),
                    _emptyStep("Post-Trade"),
                    _emptyStep("Review"),
                  ],
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt),
                  label: const Text("Save Trade Form"),
                  onPressed: _saveTradeForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= STEP 1 =================
  Step _marketContextStep() {
    return Step(
      title: const Text("Context"),
      subtitle: const Text("Market conditions"),
      isActive: _currentStep >= 0,
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            sectionCard(
              title: "Market Direction",
              icon: Icons.trending_up,
              children: [
                _dropdown(
                  "Direction",
                  data!.tradeDirections,
                  direction,
                  (v) => setState(() => direction = v),
                ),
                _dropdown(
                  "Market Bias",
                  data!.marketBiases,
                  marketBias,
                  (v) => setState(() => marketBias = v),
                ),
                _dropdown(
                  "Market State",
                  data!.marketStates,
                  marketState,
                  (v) => setState(() => marketState = v),
                ),
                _dropdown(
                  "Volatility",
                  data!.volatilities,
                  volatility,
                  (v) => setState(() => volatility = v),
                ),
              ],
            ),

            sectionCard(
              title: "Entry Logic",
              icon: Icons.login,
              children: [
                _multiSelect("Entry Reasons", data!.entryReasons, entryReasons),
                _multiSelect(
                  "Confirmations",
                  data!.entryConfirmations,
                  entryConfirmations,
                ),
                _dropdown(
                  "Entry Zone Type",
                  data!.entryZoneTypes,
                  entryZoneType,
                  (v) => setState(() => entryZoneType = v),
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
                  _multiSelect(
                    "Scaling Rules",
                    data!.scalingRules,
                    scalingRules,
                  ),

                SwitchListTile.adaptive(
                  title: const Text("Enable boost"),
                  value: willBoost,
                  onChanged: (v) => setState(() => willBoost = v),
                ),

                if (willBoost)
                  _multiSelect("Boost Rules", data!.boostRules, boostRules),
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
                    Expanded(child: _numberField("R:R", rrCtrl)),
                  ],
                ),

                _dropdown(
                  "Expected Probability",
                  data!.probabilities,
                  probability,
                  (v) => setState(() => probability = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Step _emptyStep(String title) {
    return Step(
      title: Text(title),
      content: const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "To be implemented later",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  /// ================= UI HELPERS =================
  Widget _dropdown(
    String label,
    List<dynamic> items,
    dynamic value,
    ValueChanged<dynamic> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e.id.toString(),
                child: Text(e.enName),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _multiSelect(
    String title,
    List<dynamic> options,
    List<dynamic> selected,
  ) {
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
              return FilterChip(
                label: Text(o.enName),
                selected: selected.contains(o.id),
                showCheckmark: false,
                selectedColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: selected.contains(o.id)
                      ? Theme.of(context).colorScheme.primary
                      : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (v) {
                  setState(() {
                    v ? selected.add(o.id) : selected.remove(o.id);
                  });
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

  /// ================= SAVE ACTIONS =================
  void _saveDaySettings() {
    final updated = widget.day.copyWith(
      weekend: weekend,
      noWork: noWork,
      ended: ended,
    );

    widget.cubit.updateDay(updated);

    if (widget.day.exists) {
      _dayService.update(widget.day.id, updated.toJson());
    } else {
      _dayService.create(updated.toJson());
    }
  }

  void _saveTradeForm() {
    if (!_formKey.currentState!.validate()) return;

    debugPrint("Trade form saved (API integration later)");
    // later: map fields → Trade DTO → API
  }

  Future<void> loadData() async {
    final tempData = await _dataService.getAll();

    setState(() {
      data = tempData;
    });
  }
}
