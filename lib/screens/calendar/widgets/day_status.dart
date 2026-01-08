import 'package:flutter/material.dart';

import '../../../bloc/calendar_state.dart';
import '../../../models/day_model.dart';
import '../../../services/day_service.dart';

class DayStatus extends StatefulWidget {
  final DayModel day;
  final CalendarCubit cubit;

  const DayStatus({super.key, required this.day, required this.cubit});

  @override
  State<DayStatus> createState() => _DayStatusState();
}

class _DayStatusState extends State<DayStatus> {
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
    return Row(
      children: [
        Wrap(
          spacing: 12,
          children: [
            FilterChip(
              label: const Text("Weekend"),
              selected: weekend,
              onSelected: (v) => setState(() {
                weekend = v;
                if (v) {
                  noWork = false;
                  ended = false;
                }
              }),
            ),
            FilterChip(
              label: const Text("No Work"),
              selected: noWork,
              onSelected: (v) => setState(() {
                noWork = v;
                if (v) {
                  weekend = false;
                  ended = false;
                }
              }),
            ),
            FilterChip(
              label: const Text("Ended"),
              selected: ended,
              onSelected: (v) => setState(() {
                ended = v;
                if (v) {
                  weekend = false;
                  noWork = false;
                }
              }),
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
    );
  }

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
}