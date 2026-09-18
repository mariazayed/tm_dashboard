import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/goal_category_enum.dart';
import '../../enums/goal_status_enum.dart';
import '../../models/goal_model.dart';
import '../../services/goal_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_dropdown.dart';
import '../../widgets/form_number_field.dart';
import '../../widgets/form_text_area_field.dart';

class AddGoalSheet extends StatefulWidget {
  final GoalModel? existing;

  const AddGoalSheet({super.key, this.existing});

  @override
  State<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<AddGoalSheet> {
  late TextEditingController _titleController;
  late TextEditingController _targetController;
  late TextEditingController _notesController;
  late GoalCategoryEnum _category;
  late DateTime _startDate;
  late DateTime _endDate;
  int _manualProgress = 0;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final now = DateTime.now();

    _titleController = TextEditingController(text: existing?.title ?? '');
    _targetController = TextEditingController(
      text: existing?.targetValue != null
          ? existing!.targetValue!.toStringAsFixed(0)
          : '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _category = existing?.category ?? GoalCategoryEnum.PROFIT;
    _startDate = existing?.startDate ?? DateTime(now.year, now.month, 1);
    _endDate = existing?.endDate ?? DateTime(now.year, now.month + 1, 0);
    _manualProgress = existing?.manualProgressPct ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: isStart ? _startDate : _endDate,
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _applyPreset(int days) {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = _startDate.add(Duration(days: days));
    });
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _saving = true);

    final targetValue = _targetController.text.trim().isEmpty
        ? null
        : double.tryParse(_targetController.text.trim());

    try {
      if (_isEdit) {
        final updated = widget.existing!.copyWith(
          title: _titleController.text.trim(),
          category: _category,
          targetValue: targetValue,
          startDate: _startDate,
          endDate: _endDate,
          manualProgressPct: _category == GoalCategoryEnum.MANUAL ? _manualProgress : null,
          notes: _notesController.text.trim(),
        );
        await GoalService.update(widget.existing!.id, updated.toUpdateJson());
      } else {
        final draft = GoalModel(
          id: 0,
          title: _titleController.text.trim(),
          category: _category,
          status: GoalStatusEnum.ACTIVE,
          targetValue: targetValue,
          startDate: _startDate,
          endDate: _endDate,
          manualProgressPct: _category == GoalCategoryEnum.MANUAL ? _manualProgress : null,
          notes: _notesController.text.trim(),
        );
        await GoalService.create([draft.toCreateJson()]);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save goal: $e')),
        );
      }
    }
  }

  String _targetHint() {
    switch (_category) {
      case GoalCategoryEnum.PROFIT:
        return 'Target profit (\$)';
      case GoalCategoryEnum.TRADE_QUALITY:
        return 'Target win rate (%)';
      case GoalCategoryEnum.DISCIPLINE:
        return 'Target adherence % (default 100)';
      case GoalCategoryEnum.MANUAL:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            children: [
              Text(
                _isEdit ? 'Edit Goal' : 'New Goal',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Goal title'),
          ),
          const SizedBox(height: 4),
          FormDropdown<GoalCategoryEnum>(
            label: 'Category',
            items: GoalCategoryEnum.values,
            value: _category,
            labelBuilder: (c) => c.label,
            onChanged: (c) => setState(() => _category = c ?? _category),
          ),
          if (_category != GoalCategoryEnum.MANUAL)
            FormNumberField(
              label: _targetHint(),
              controller: _targetController,
            ),
          if (_category == GoalCategoryEnum.MANUAL) ...[
            Text('Progress: $_manualProgress%', style: TextStyle(color: colorScheme.onSurfaceVariant)),
            Slider(
              value: _manualProgress.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '$_manualProgress%',
              onChanged: (v) => setState(() => _manualProgress = v.round()),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text('Start: ${fmt.format(_startDate)}'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(false),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text('End: ${fmt.format(_endDate)}'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(label: const Text('This week'), onPressed: () => _applyPreset(7)),
              ActionChip(label: const Text('This month'), onPressed: () => _applyPreset(30)),
              ActionChip(label: const Text('This quarter'), onPressed: () => _applyPreset(90)),
            ],
          ),
          const SizedBox(height: 12),
          FormTextAreaField(label: 'Notes (optional)', controller: _notesController),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text(_isEdit ? 'Save Changes' : 'Create Goal'),
            ),
          ),
        ],
      ),
    );
  }
}
