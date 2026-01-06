import 'package:flutter/material.dart';
import 'package:tm_dashboard/services/day_service.dart';

import '../../../bloc/calendar_state.dart';
import '../../../models/day_model.dart';
import '../../../trade_cycle_forms/trade_plan_form.dart';

class DayEditDialog extends StatefulWidget {
  final DayModel day;
  final CalendarCubit cubit;

  const DayEditDialog({super.key, required this.day, required this.cubit});

  @override
  State<DayEditDialog> createState() => _DayEditDialogState();
}

class _DayEditDialogState extends State<DayEditDialog> {
  final DayService _dayService = DayService();

  int _currentStep = 0;

  late bool weekend;
  late bool noWork;
  late bool ended;

  @override
  void initState() {
    super.initState();
    weekend = widget.day.weekend;
    noWork = widget.day.noWork;
    ended = widget.day.ended;
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

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt),
                  label: const Text("Save"),
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

              // Align(
              //   alignment: Alignment.centerRight,
              //   child: ElevatedButton.icon(
              //     icon: const Icon(Icons.save_alt),
              //     label: const Text("Save Trade Form"),
              //     onPressed: _saveTradeForm,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Step _marketContextStep() {
    return Step(
      title: const Text("Context"),
      subtitle: const Text("Market conditions"),
      isActive: _currentStep >= 0,
      content: MarketContextForm(),
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

    Navigator.of(context).pop();
  }

  // void _saveTradeForm() {
  //   if (!_formKey.currentState!.validate()) return;
  //
  //   debugPrint("Trade form saved (API integration later)");
  //   // later: map fields → Trade DTO → API
  // }
}
