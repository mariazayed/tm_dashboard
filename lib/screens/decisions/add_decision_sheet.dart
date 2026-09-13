import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../enums/decision_category_enum.dart';
import '../../enums/decision_status_enum.dart';
import '../../models/decision_model.dart';
import '../../services/decision_service.dart';
import '../../widgets/form_dropdown.dart';
import '../../widgets/form_text_area_field.dart';
import '../../widgets/md_editor_field.dart';
import 'decision_detail_sheet.dart';

class AddDecisionSheet extends StatefulWidget {
  final DecisionModel? existing;

  // Every other decision, used to populate the "reconsiders" dropdown by
  // title instead of a raw number field, and to preview the selected one
  // inline. Passed in from DecisionsScreen, which already has the full
  // list loaded.
  final List<DecisionModel> allDecisions;

  const AddDecisionSheet({super.key, this.existing, required this.allDecisions});

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
  int? _relatedDecisionNumber;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  // Every decision except the one being edited (a decision can't reconsider
  // itself), sorted so the dropdown reads in the same order as the log.
  List<DecisionModel> get _relatableDecisions {
    final list = widget.allDecisions
        .where((d) => widget.existing == null || d.id != widget.existing!.id)
        .toList()
      ..sort((a, b) => (a.decisionNumber ?? 0).compareTo(b.decisionNumber ?? 0));
    return list;
  }

  DecisionModel? get _selectedRelated {
    if (_relatedDecisionNumber == null) return null;
    for (final d in widget.allDecisions) {
      if (d.decisionNumber == _relatedDecisionNumber) return d;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _reasoningController = TextEditingController(text: existing?.reasoning ?? '');
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _category = existing?.category ?? DecisionCategoryEnum.SYSTEM;
    _decisionDate = existing?.decisionDate ?? DateTime.now();
    _relatedDecisionNumber = existing?.relatedDecisionNumber;
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
    if (picked == null) return;
    setState(() => _decisionDate = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) return;

    setState(() => _saving = true);

    try {
      if (_isEdit) {
        final updated = widget.existing!.copyWith(
          decisionDate: _decisionDate,
          title: _titleController.text.trim(),
          category: _category,
          description: _descriptionController.text.trim(),
          reasoning: _reasoningController.text.trim(),
          relatedDecisionNumber: _relatedDecisionNumber,
          clearRelatedDecisionNumber: _relatedDecisionNumber == null,
          notes: _notesController.text.trim(),
        );
        await DecisionService.update(widget.existing!.id, updated.toUpdateJson());
      } else {
        // decisionNumber is left null here -- the server assigns it on
        // create (continues the log's 1, 2, 3... sequence).
        final draft = DecisionModel(
          id: 0,
          decisionDate: _decisionDate,
          title: _titleController.text.trim(),
          category: _category,
          status: DecisionStatusEnum.ACTIVE,
          description: _descriptionController.text.trim(),
          reasoning: _reasoningController.text.trim(),
          relatedDecisionNumber: _relatedDecisionNumber,
          notes: _notesController.text.trim(),
        );
        await DecisionService.create([draft.toCreateJson()]);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save decision: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final related = _selectedRelated;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            children: [
              Text(
                _isEdit ? 'Edit Decision' : 'New Decision',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          if (_isEdit && widget.existing!.decisionNumber != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Decision #${widget.existing!.decisionNumber}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 4),
          FormDropdown<DecisionCategoryEnum>(
            label: 'Category',
            items: DecisionCategoryEnum.values,
            value: _category,
            labelBuilder: (c) => c.label,
            onChanged: (c) => setState(() => _category = c ?? _category),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _pickDate,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('Date: ${fmt.format(_decisionDate)}'),
            ),
          ),
          const SizedBox(height: 16),
          MdEditorField(label: 'What was decided', controller: _descriptionController),
          MdEditorField(
            label: 'Why (reasoning, optional)',
            controller: _reasoningController,
            minLines: 3,
            maxLines: 10,
          ),
          const SizedBox(height: 4),
          FormDropdown<DecisionModel?>(
            label: 'Reconsiders decision (optional)',
            items: [null, ..._relatableDecisions],
            value: related,
            labelBuilder: (d) => d == null ? 'None' : '#${d.decisionNumber} — ${d.title}',
            onChanged: (d) => setState(() => _relatedDecisionNumber = d?.decisionNumber),
          ),
          if (related != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 2),
              child: InkWell(
                onTap: () => showDecisionDetailSheet(context, related, widget.allDecisions),
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'View decision #${related.decisionNumber}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          FormTextAreaField(label: 'Notes / outcome (optional)', controller: _notesController),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_saving ? 'Saving...' : (_isEdit ? 'Save Changes' : 'Add Decision')),
            ),
          ),
        ],
      ),
    );
  }
}
