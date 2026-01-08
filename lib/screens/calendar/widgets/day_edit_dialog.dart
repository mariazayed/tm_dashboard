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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: 1000,
        height: 800,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 24, 16),
              child: Row(
                children: [
                  Text(
                    "Day ${widget.day.date.day}",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ================= DAY CHECKBOXES =================
                    Row(
                      children: [
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
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text("Save Changes"),
                          onPressed: _saveDaySettings,
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(),
                    ),

                    /// ================= STEPPER FORM =================
                    Text(
                      "Trade Planning",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 550,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: Colors.transparent,
                        ),
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
                            return Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: details.onStepContinue,
                                    child: Text(_currentStep == 4 ? "Complete" : "Continue"),
                                  ),
                                  const SizedBox(width: 12),
                                  if (_currentStep > 0)
                                    TextButton(
                                      onPressed: details.onStepCancel,
                                      child: const Text("Back"),
                                    ),
                                ],
                              ),
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
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      content: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(Icons.construction_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Under Development",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "This section will be available in a future update.",
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
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
  // }
}
