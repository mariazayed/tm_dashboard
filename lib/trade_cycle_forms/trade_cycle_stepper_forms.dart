import 'package:flutter/material.dart';
import 'package:tm_dashboard/trade_cycle_forms/trade_plan_form.dart';

import '../widgets/in_development.dart';

class TradeCycleStepperForms extends StatefulWidget {
  @override
  State<TradeCycleStepperForms> createState() => _TradeCycleStepperFormsState();
}

class _TradeCycleStepperFormsState extends State<TradeCycleStepperForms> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }

  Step _marketContextStep() {
    return Step(
      title: const Text("Planning"),
      subtitle: const Text("Market conditions"),
      isActive: _currentStep >= 0,
      content: TradePlanForm(),
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
        child: InDevelopment(),
      ),
    );
  }
}