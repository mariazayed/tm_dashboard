import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/decision_category_enum.dart';
import '../../enums/decision_status_enum.dart';
import '../../models/decision_model.dart';
import '../../services/decision_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/form_dropdown.dart';
import '../../widgets/form_text_area_field.dart';
import '../../widgets/md_editor_field.dart';
import 'decision_detail_sheet.dart';
import '../../configs/feature_gate.dart';
import '../../services/feature_service.dart';

class AddDecisionSheet extends StatefulWidget {
  final DecisionModel? existing;
  final List<DecisionModel> allDecisions;

  const AddDecisionSheet({
    super.key,
    this.existing,
    required this.allDecisions,
  });

  @override
  State<AddDecisionSheet> createState() => _AddDecisionSheetState();
}

class _AddDecisionSheetState extends State<AddDecisionSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _reasoningController;
  late TextEditingController _notesController;
  late DecisionCategoryEnum _category;
  late DateTime _decisionDate;
  late List<int> _relatedDecisionNumbers;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  List<DecisionModel> get _relatableDecisions {
    final list =
        widget.allDecisions
            .where(
              (d) => widget.existing == null || d.id != widget.existing!.id,
            )
            .where((d) => d.decisionNumber != null)
            .toList()
          ..sort(
            (a, b) => (b.decisionNumber ?? 0).compareTo(a.decisionNumber ?? 0),
          );
    return list;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _reasoningController = TextEditingController(
      text: existing?.reasoning ?? '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _category = existing?.category ?? DecisionCategoryEnum.SYSTEM;
    _decisionDate = existing?.decisionDate ?? DateTime.now();
    _relatedDecisionNumbers = [...existing?.relatedDecisionNumbers ?? const []];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reasoningController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _decisionDate,
    );
    if (picked == null) {
      return;
    }
    setState(() => _decisionDate = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      return;
    }

    setState(() => _saving = true);

    try {
      final reasoning = _emptyToNull(_reasoningController.text);
      final notes = _emptyToNull(_notesController.text);

      if (_isEdit) {
        final updated = widget.existing!.copyWith(
          decisionDate: _decisionDate,
          title: _titleController.text.trim(),
          category: _category,
          description: _descriptionController.text.trim(),
          reasoning: reasoning,
          relatedDecisionNumbers: _relatedDecisionNumbers,
          notes: notes,
        );
        await DecisionService.update(
          widget.existing!.id,
          updated.toUpdateJson(),
        );
      } else {
        final draft = DecisionModel(
          id: 0,
          decisionDate: _decisionDate,
          title: _titleController.text.trim(),
          category: _category,
          status: DecisionStatusEnum.ACTIVE,
          description: _descriptionController.text.trim(),
          reasoning: reasoning,
          relatedDecisionNumbers: _relatedDecisionNumbers,
          notes: notes,
        );
        await DecisionService.create([draft.toCreateJson()]);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save decision: $e')));
      }
    }
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        28 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  _isEdit ? 'Edit decision' : 'New decision',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (_isEdit && widget.existing!.decisionNumber != null)
            Text(
              'Decision #${widget.existing!.decisionNumber}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 4),
          FormDropdown<DecisionCategoryEnum>(
            label: 'Category',
            items: {
              ...decisionCategoriesFor(tradingEnabled: Features.tradingEnabled),
              _category,
            }.toList(),
            value: _category,
            labelBuilder: (c) => c.label,
            onChanged: (c) => setState(() => _category = c ?? _category),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            onPressed: _pickDate,
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(fmt.format(_decisionDate)),
            ),
          ),
          const SizedBox(height: 16),
          MdEditorField(
            label: 'What was decided',
            controller: _descriptionController,
          ),
          MdEditorField(
            label: 'Why (reasoning, optional)',
            controller: _reasoningController,
            minLines: 3,
            maxLines: 10,
          ),
          const SizedBox(height: 6),
          Text(
            'Reconsiders',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _buildRelatedPicker(context),
          const SizedBox(height: 14),
          FormTextAreaField(
            label: 'Notes / outcome (optional)',
            controller: _notesController,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            onPressed: _saving ? null : _submit,
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _saving
                    ? 'Saving...'
                    : (_isEdit ? 'Save changes' : 'Add decision'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final relatable = _relatableDecisions;
    if (relatable.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          'No earlier decisions available',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: relatable.map((decision) {
        final number = decision.decisionNumber!;
        final selected = _relatedDecisionNumbers.contains(number);

        return FilterChip(
          selected: selected,
          label: Text('#$number ${decision.title}'),
          onSelected: (isSelected) {
            setState(() {
              if (isSelected) {
                _relatedDecisionNumbers = {
                  ..._relatedDecisionNumbers,
                  number,
                }.toList()..sort();
              } else {
                _relatedDecisionNumbers = _relatedDecisionNumbers
                    .where((item) => item != number)
                    .toList();
              }
            });
          },
          onDeleted: selected ? () => _showRelatedDecision(number) : null,
          deleteIcon: const Icon(Icons.visibility_outlined, size: 16),
        );
      }).toList(),
    );
  }

  void _showRelatedDecision(int decisionNumber) {
    for (final decision in widget.allDecisions) {
      if (decision.decisionNumber == decisionNumber) {
        showDecisionDetailSheet(context, decision, widget.allDecisions);
        return;
      }
    }
  }
}
