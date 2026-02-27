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
    // Null-safe assignments
    weekend = widget.day.weekend ?? false;
    noWork = widget.day.noWork ?? false;
    ended = widget.day.ended ?? false;

    _notes = widget.day.notes ?? '';
    _notesController.text = _notes;

    _psychologyRate = widget.day.psychologyRate; // no default
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _emojiForScore(int value) {
    if (value <= 2) return "😵";
    if (value <= 4) return "😕";
    if (value <= 6) return "😐";
    if (value <= 8) return "🙂";
    return "🧠🔥";
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
          ],
        ),

        const SizedBox(height: 32),

        /// -------- Psychology Slider --------
        Text(
          "Psychology Rating",
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.shade100,
                Colors.orange.shade100,
                Colors.yellow.shade100,
                Colors.green.shade100,
                Colors.blue.shade100,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                _psychologyRate == null
                    ? "Select your trading psychology mood"
                    : "${_emojiForScore(_psychologyRate!.value)}  ${_psychologyRate!.value}/10",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: (_psychologyRate?.value ?? 1).toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: Colors.deepPurple,
                inactiveColor: Colors.white,
                onChanged: (value) {
                  setState(() {
                    _psychologyRate = ScoreEnum.fromValue(value.round());
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("😵"),
                  Text("😕"),
                  Text("😐"),
                  Text("🙂"),
                  Text("🧠🔥"),
                ],
              ),
            ],
          ),
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
      psychologyRate: _psychologyRate,
      noWork: noWork,
      ended: ended,
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
