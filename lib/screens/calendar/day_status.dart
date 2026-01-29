import 'package:flutter/material.dart';

import 'calendar_state.dart';
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
  final TextEditingController _notesController = TextEditingController();

  // Safe default values
  bool weekend = false;
  bool noWork = false;
  bool ended = false;

  String _notes = ''; // Safe default for notes

  @override
  void initState() {
    super.initState();
    _syncFromDay();
  }

  @override
  void didUpdateWidget(covariant DayStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day.id != widget.day.id) {
      _syncFromDay();
    }
  }

  void _syncFromDay() {
    // Null-safe assignments
    weekend = widget.day.weekend ?? false;
    noWork = widget.day.noWork ?? false;
    ended = widget.day.ended ?? false;

    _notes = widget.day.notes ?? '';
    _notesController.text = _notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// -------- Status Chips --------
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

        const SizedBox(height: 24),

        /// -------- Notes --------
        Text("Notes", style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        TextField(
          controller: _notesController,
          maxLines: 6,
          onChanged: (v) => _notes = v, // Keep notes in sync
          decoration: InputDecoration(
            hintText: "Write notes about this trading day...",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 32),

        /// -------- Save Button --------
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Save Changes"),
            onPressed: _saveDaySettings,
          ),
        ),
      ],
    );
  }

  void _saveDaySettings() {
    final updated = widget.day.copyWith(
      weekend: weekend,
      noWork: noWork,
      ended: ended,
      notes: _notesController.text.trim(),
    );

    widget.cubit.updateDay(updated);

    if (widget.day.exists) {
      _dayService.update(widget.day.id, updated.toJson());
    } else {
      print('updated2.toJson() ${updated.toJson()}');
      _dayService.create(updated.toJson());
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
