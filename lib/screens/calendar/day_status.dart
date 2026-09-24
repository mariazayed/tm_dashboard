import 'package:flutter/material.dart';

import '../../../enums/score_enum.dart';
import '../../../models/day_model.dart';
import '../../../services/day_service.dart';
import 'calendar_state.dart';

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
  bool isImportant = false;

  String _notes = '';

  ScoreEnum? _psychologyRate; // nullable → no default value

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
    weekend = widget.day.weekend;
    noWork = widget.day.noWork;
    ended = widget.day.ended;
    isImportant = widget.day.isImportant;

    _notes = widget.day.notes;
    _notesController.text = _notes;

    _psychologyRate = widget.day.psychologyRate; // no default
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// Emoji for each exact score
  String _emojiForScore(int value) {
    switch (value) {
      case 1:
        return "😡"; // TERRIBLE
      case 2:
        return "😖"; // VERY_POOR
      case 3:
        return "😞"; // POOR
      case 4:
        return "😕"; // BELOW_AVERAGE
      case 5:
        return "😐"; // AVERAGE
      case 6:
        return "🙂"; // ABOVE_AVERAGE
      case 7:
        return "😌"; // GOOD
      case 8:
        return "😎"; // VERY_GOOD
      case 9:
        return "🚀"; // EXCELLENT
      case 10:
        return "🧠🔥"; // WORLD_CLASS
      default:
        return "";
    }
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
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text("Important"),
              value: isImportant,
              onChanged: (v) => setState(() => isImportant = v ?? false),
            ),
          ],
        ),

        const SizedBox(height: 32),

        /// -------- Psychology Slider --------
        Text(
          "Psychology Rating",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),

        Column(
          children: [
            Text(
              _psychologyRate == null
                  ? "Select your day psychology"
                  : "${_emojiForScore(_psychologyRate!.value)}  ${_psychologyRate!.value}/10",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            Slider(
              value: (_psychologyRate?.value ?? 1).toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _psychologyRate?.value.toString(),
              onChanged: (value) {
                setState(() {
                  _psychologyRate = ScoreEnum.fromValue(value.round());
                });
              },
            ),

            const SizedBox(height: 12),

            /// Emoji scale row (1 → 10)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(10, (index) {
                final score = index + 1;
                return Text(
                  _emojiForScore(score),
                  style: const TextStyle(fontSize: 16),
                );
              }),
            ),
          ],
        ),

        const SizedBox(height: 32),

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
            fillColor: Theme.of(context).colorScheme.surface,
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
      psychologyRate: _psychologyRate,
      noWork: noWork,
      ended: ended,
      isImportant: isImportant,
      notes: _notesController.text.trim(),
    );

    widget.cubit.updateDay(updated);

    if (widget.day.exists) {
      _dayService.update(widget.day.id, updated.toJson());
    } else {
      _dayService.create(updated.toJson());
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
