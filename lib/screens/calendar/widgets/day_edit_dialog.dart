import 'package:flutter/material.dart';

import '../../../bloc/calendar_state.dart';
import '../models/day_card_model.dart';

class DayEditDialog extends StatefulWidget {
  final DayCardModel day;
  final CalendarCubit cubit;

  const DayEditDialog({super.key, required this.day, required this.cubit});

  @override
  State<DayEditDialog> createState() => _DayEditDialogState();
}

class _DayEditDialogState extends State<DayEditDialog> {
  late bool isDone;
  late double progress;
  late bool isSkipDay;
  IconData? icon;

  @override
  void initState() {
    super.initState();
    isDone = widget.day.weekend;
    isSkipDay = widget.day.noWork;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Day ${widget.day.date.day}"),
      content: SizedBox(
        width: 300,
        height: 250,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Done:"),
                Switch(
                  value: isDone,
                  onChanged: (v) => setState(() => isDone = v),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Skip Day:"),
                Checkbox(
                  value: isSkipDay,
                  onChanged: (v) => setState(() => isSkipDay = v ?? false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Progress:"),
                Slider(
                  value: progress,
                  onChanged: (v) => setState(() => progress = v),
                  divisions: 10,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Icon:"),
                DropdownButton<IconData>(
                  value: icon,
                  hint: const Text("Select"),
                  items: const [
                    DropdownMenuItem(
                      child: Icon(Icons.star),
                      value: Icons.star,
                    ),
                    DropdownMenuItem(
                      child: Icon(Icons.favorite),
                      value: Icons.favorite,
                    ),
                    DropdownMenuItem(
                      child: Icon(Icons.check),
                      value: Icons.check,
                    ),
                  ],
                  onChanged: (v) => setState(() => icon = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final updated = widget.day.copyWith(
                  weekend: isDone,
                  noWork: isSkipDay,
                );
                widget.cubit.updateDay(updated);
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
