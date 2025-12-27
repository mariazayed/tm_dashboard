import 'package:flutter/material.dart';
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
  String? direction;
  String? marketBias;
  String? marketState;
  String? volatility;

  List<String> entryReasons = [];
  List<String> entryConfirmations = [];
  String? entryZoneType;

  late StaticDataResponse data;
  final entryZoneStartCtrl = TextEditingController();
  final entryZoneEndCtrl = TextEditingController();
  final estimatedEntryCtrl = TextEditingController();

  final invalidationStartCtrl = TextEditingController();
  final invalidationEndCtrl = TextEditingController();
  String? invalidationCondition;

  bool willPyramid = false;
  bool willBoost = false;

  List<String> scalingRules = [];
  List<String> boostRules = [];

  final lotSizeCtrl = TextEditingController();
  final rrCtrl = TextEditingController();

  String? focusLevel;
  String? stressLevel;
  String? confidenceLevel;
  String? probability;

  /// ---------------- ENUM MOCK DATA ----------------
  final directions = ['BUY', 'SELL'];
  final marketBiases = ['BULLISH', 'BEARISH', 'RANGE'];
  final marketStates = ['TRENDING', 'RANGING', 'CHOPPY'];
  final volatilityLevels = ['LOW', 'MEDIUM', 'HIGH'];

  final entryReasonOptions = [
    'SUPPORT_RESISTANCE',
    'BREAKOUT',
    'TREND_CONTINUATION',
  ];

  final confirmationOptions = ['CANDLE_PATTERN', 'VOLUME', 'INDICATOR'];

  final scalingRuleOptions = ['FIXED', 'ATR_BASED'];
  final boostRuleOptions = ['NEWS', 'MOMENTUM'];

  final scoreOptions = ['LOW', 'MEDIUM', 'HIGH'];
  final probabilityOptions = ['LOW', 'MEDIUM', 'HIGH'];

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
              Text(
                "Day Settings",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              CheckboxListTile(
                title: const Text("Weekend"),
                value: weekend,
                onChanged: (v) => setState(() => weekend = v ?? false),
              ),
              CheckboxListTile(
                title: const Text("No Work"),
                value: noWork,
                onChanged: (v) => setState(() => noWork = v ?? false),
              ),
              CheckboxListTile(
                title: const Text("Is Ended"),
                value: ended,
                onChanged: (v) => setState(() => ended = v ?? false),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save Day Settings"),
                  onPressed: _saveDaySettings,
                ),
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
      isActive: _currentStep >= 0,
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            _dropdown(
              "Direction",
              directions,
              direction,
              (v) => setState(() => direction = v),
            ),
            _dropdown(
              "Market Bias",
              marketBiases,
              marketBias,
              (v) => setState(() => marketBias = v),
            ),
            _dropdown(
              "Market State",
              marketStates,
              marketState,
              (v) => setState(() => marketState = v),
            ),
            _dropdown(
              "Volatility",
              volatilityLevels,
              volatility,
              (v) => setState(() => volatility = v),
            ),

            const Divider(),

            _multiSelect("Entry Reasons", entryReasonOptions, entryReasons),
            _multiSelect(
              "Entry Confirmations",
              confirmationOptions,
              entryConfirmations,
            ),

            _dropdown(
              "Entry Zone Type",
              ['RANGE', 'LEVEL'],
              entryZoneType,
              (v) => setState(() => entryZoneType = v),
            ),

            _numberField("Entry Zone Start", entryZoneStartCtrl),
            _numberField("Entry Zone End", entryZoneEndCtrl),
            _numberField("Estimated Entry", estimatedEntryCtrl),

            const Divider(),

            SwitchListTile(
              title: const Text("Will Pyramid"),
              value: willPyramid,
              onChanged: (v) => setState(() => willPyramid = v),
            ),

            _multiSelect("Scaling Rules", scalingRuleOptions, scalingRules),

            SwitchListTile(
              title: const Text("Will Boost"),
              value: willBoost,
              onChanged: (v) => setState(() => willBoost = v),
            ),

            _multiSelect("Boost Rules", boostRuleOptions, boostRules),

            const Divider(),

            _numberField("Lot Size", lotSizeCtrl),
            _numberField("Risk / Reward", rrCtrl),

            const Divider(),

            _dropdown(
              "Focus Level",
              scoreOptions,
              focusLevel,
              (v) => setState(() => focusLevel = v),
            ),
            _dropdown(
              "Stress Level",
              scoreOptions,
              stressLevel,
              (v) => setState(() => stressLevel = v),
            ),
            _dropdown(
              "Confidence Level",
              scoreOptions,
              confidenceLevel,
              (v) => setState(() => confidenceLevel = v),
            ),
            _dropdown(
              "Expected Probability",
              probabilityOptions,
              probability,
              (v) => setState(() => probability = v),
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
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
    List<String> options,
    List<String> selected,
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
                label: Text(o),
                selected: selected.contains(o),
                onSelected: (v) {
                  setState(() {
                    v ? selected.add(o) : selected.remove(o);
                  });
                },
              );
            }).toList(),
          ),
        ],
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
    data = await _dataService.getAll();
    print(data);
  }
}
