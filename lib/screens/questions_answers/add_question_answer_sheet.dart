import 'package:flutter/material.dart';

import '../../models/question_category_model.dart';
import '../../models/question_answer_model.dart';
import '../../services/question_answer_service.dart';
import '../../widgets/md_editor_field.dart';

class AddQuestionAnswerSheet extends StatefulWidget {
  final QuestionAnswerModel? existing;
  final List<QuestionCategoryModel> categories;

  const AddQuestionAnswerSheet({
    super.key,
    this.existing,
    required this.categories,
  });

  @override
  State<AddQuestionAnswerSheet> createState() => _AddQuestionAnswerSheetState();
}

class _AddQuestionAnswerSheetState extends State<AddQuestionAnswerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  QuestionCategoryModel? _selectedCategory;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(
      text: widget.existing?.question ?? '',
    );
    _answerController = TextEditingController(
      text: widget.existing?.answer ?? '',
    );
    _selectedCategory = widget.existing?.category;
    if (_selectedCategory != null &&
        !widget.categories.any((c) => c.id == _selectedCategory!.id)) {
      _selectedCategory = null;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final model = QuestionAnswerModel(
        id: widget.existing?.id ?? 0,
        question: _questionController.text.trim(),
        answer: _answerController.text.trim(),
        category: _selectedCategory,
        notes: widget.existing?.notes,
      );

      if (_isEditing) {
        await QuestionAnswerService.update(
          widget.existing!.id,
          model.toUpdateJson(),
        );
      } else {
        await QuestionAnswerService.create([model.toCreateJson()]);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save question: $e')));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit Question' : 'New Question',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategory?.id,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    setState(() {
                      for (final category in widget.categories) {
                        if (category.id == id) {
                          _selectedCategory = category;
                          return;
                        }
                      }
                      _selectedCategory = null;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Category is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _questionController,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Question is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                MdEditorField(
                  label: 'Answer',
                  controller: _answerController,
                  minLines: 12,
                  maxLines: 24,
                ),
                if (_answerController.text.trim().isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Answer is required',
                      style: TextStyle(color: colorScheme.error, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () {
                            if (_answerController.text.trim().isEmpty) {
                              setState(() {});
                              return;
                            }
                            _save();
                          },
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_isEditing ? 'Save Changes' : 'Save Question'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
