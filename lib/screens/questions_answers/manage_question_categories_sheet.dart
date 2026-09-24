import 'package:flutter/material.dart';

import '../../models/question_category_model.dart';
import '../../services/question_category_service.dart';

class ManageQuestionCategoriesSheet extends StatefulWidget {
  const ManageQuestionCategoriesSheet({super.key});

  @override
  State<ManageQuestionCategoriesSheet> createState() =>
      _ManageQuestionCategoriesSheetState();
}

class _ManageQuestionCategoriesSheetState
    extends State<ManageQuestionCategoriesSheet> {
  late Future<List<QuestionCategoryModel>> _future;
  final TextEditingController _controller = TextEditingController();
  QuestionCategoryModel? _editing;
  final Set<int> _pendingIds = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _future = QuestionCategoryService.getAllPaged();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = QuestionCategoryService.getAllPaged();
    });
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final model = QuestionCategoryModel(id: _editing?.id ?? 0, name: name);
      if (_editing == null) {
        await QuestionCategoryService.create(model.toCreateJson());
      } else {
        await QuestionCategoryService.update(
          _editing!.id,
          model.toUpdateJson(),
        );
      }

      setState(() {
        _controller.clear();
        _editing = null;
        _isSaving = false;
      });
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save category: $e')));
    }
  }

  Future<void> _confirmDelete(QuestionCategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category'),
        content: Text(
          'Delete "${category.name}"? Existing questions keep showing it, but it will no longer be available for new questions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _pendingIds.add(category.id));
    try {
      await QuestionCategoryService.delete(category.id);
      if (_editing?.id == category.id) {
        _controller.clear();
        _editing = null;
      }
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete category: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _pendingIds.remove(category.id));
    }
  }

  void _startEdit(QuestionCategoryModel category) {
    setState(() {
      _editing = category;
      _controller.text = category.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Question Categories',
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        labelText: _editing == null
                            ? 'New category'
                            : 'Rename category',
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _save(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_editing == null ? Icons.add : Icons.save),
                    label: Text(_editing == null ? 'Add' : 'Save'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FutureBuilder<List<QuestionCategoryModel>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load categories:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  final categories = snapshot.data ?? [];
                  if (categories.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Text(
                        'No categories yet',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final busy = _pendingIds.contains(category.id);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (busy)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else ...[
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: () => _startEdit(category),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () => _confirmDelete(category),
                                icon: const Icon(Icons.delete_outline),
                                color: colorScheme.error,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
