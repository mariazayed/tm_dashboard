import 'package:flutter/material.dart';
import 'package:tm_dashboard/trade_cycle_forms/trade_plan_form.dart';

import '../widgets/in_development.dart';

class TradeCycleStepperForms extends StatefulWidget {
  const TradeCycleStepperForms({super.key});

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
        child: Column(
          children: [
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                type: StepperType.horizontal,
                elevation: 0,
                margin: EdgeInsets.zero,
                onStepTapped: (step) => setState(() => _currentStep = step),
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                controlsBuilder: (context, details) => const SizedBox.shrink(),
                steps: [
                  _marketContextStep(),
                  _emptyStep("Trade Management", 1),
                  _emptyStep("Execution", 2),
                  _emptyStep("Post-Trade", 3),
                  _emptyStep("Review", 4),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _onStepContinue,
                    child: Text(_currentStep == 4 ? "Complete" : "Continue"),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _onStepCancel,
                      child: const Text("Back"),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Step _marketContextStep() {
    return Step(
      title: const Text("Planning"),
      subtitle: const Text("Market conditions"),
      isActive: _currentStep >= 0,
      content: TradePlanForm(),
    );
  }

  Step _emptyStep(String title, int index) {
    return Step(
      title: Text(title),
      isActive: _currentStep >= index,
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