import 'package:flutter/material.dart';

import '../../../bloc/calendar_state.dart';
import '../../../models/day_model.dart';
import '../../../trade_cycle_forms/trade_cycle_stepper_forms.dart';
import 'day_status.dart';

class DayEditDialog extends StatefulWidget {
  final DayModel day;
  final CalendarCubit cubit;

  const DayEditDialog({super.key, required this.day, required this.cubit});

  @override
  State<DayEditDialog> createState() => _DayEditDialogState();
}

enum _DialogView { status, forms }

class _DayEditDialogState extends State<DayEditDialog> {

  _DialogView _selectedView = _DialogView.status;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Day ${widget.day.date.day}",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<_DialogView>(
                          segments: const [
                            ButtonSegment(
                              value: _DialogView.status,
                              label: Text("Day Status"),
                              icon: Icon(Icons.edit_calendar),
                            ),
                            ButtonSegment(
                              value: _DialogView.forms,
                              label: Text("Lifecycle Forms"),
                              icon: Icon(Icons.assignment),
                            ),
                          ],
                          selected: {_selectedView},
                          onSelectionChanged: (Set<_DialogView> newSelection) {
                            setState(() {
                              _selectedView = newSelection.first;
                            });
                          },
                        ),
                      ],
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
                      if (_selectedView == _DialogView.status) ...[
                        DayStatus(day: widget.day, cubit: widget.cubit,),
                      ],

                      if (_selectedView == _DialogView.forms) ...[
                        TradeCycleStepperForms(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
