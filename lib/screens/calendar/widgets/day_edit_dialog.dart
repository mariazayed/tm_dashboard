import 'package:flutter/material.dart';
import 'package:tm_dashboard/services/day_service.dart';

import '../../../bloc/calendar_state.dart';
import '../../../models/day_model.dart';

class DayEditDialog extends StatefulWidget {
  final DayModel day;
  final CalendarCubit cubit;

  const DayEditDialog({super.key, required this.day, required this.cubit});

  @override
  State<DayEditDialog> createState() => _DayEditDialogState();
}

class _DayEditDialogState extends State<DayEditDialog> {
  final DayService _dayService = DayService();

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
        width: 300,
        height: 200,
        child: Column(
          children: [
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
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final updated = widget.day.copyWith(
                  weekend: weekend,
                  noWork: noWork,
                  ended: ended,
                );
                print(updated.toJson());
                widget.cubit.updateDay(updated);
                if (widget.day.exists) {
                  print("update");
                  _dayService.update(widget.day.id, updated.toJson());
                } else {
                  print("create");
                  _dayService.create(updated.toJson());
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
