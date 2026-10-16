import 'package:flutter/material.dart';

import '../../models/reminder_note_category_model.dart';
import '../../services/reminder_notes_service.dart';

class ReminderNoteCategoriesDialog extends StatefulWidget {
  const ReminderNoteCategoriesDialog({
    super.key,
    required this.categories,
    required this.onChanged,
  });
  final List<ReminderNoteCategoryModel> categories;
  final Future<void> Function() onChanged;

  @override
  State<ReminderNoteCategoriesDialog> createState() =>
      _ReminderNoteCategoriesDialogState();
}

class _ReminderNoteCategoriesDialogState
    extends State<ReminderNoteCategoriesDialog> {
  late List<ReminderNoteCategoryModel> _categories = [...widget.categories];
  bool _busy = false;

  Future<void> _reload() async {
    final categories = await ReminderNotesService.getCategories();
    if (mounted) setState(() => _categories = categories);
    await widget.onChanged();
  }

  Future<String?> _nameDialog({String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial == null ? 'Create category' : 'Rename category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Category name'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return name?.trim().isEmpty == true ? null : name?.trim();
  }

  Future<void> _create() async {
    final name = await _nameDialog();
    if (name == null) return;
    await _run(() async {
      await ReminderNotesService.createCategory(name);
      await _reload();
    });
  }

  Future<void> _rename(ReminderNoteCategoryModel category) async {
    final name = await _nameDialog(initial: category.name);
    if (name == null || name == category.name) return;
    await _run(() async {
      await ReminderNotesService.updateCategory(category.id, name);
      await _reload();
    });
  }

  Future<void> _delete(ReminderNoteCategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          '“${category.name}” will be removed. Notes in this category will become uncategorized.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await ReminderNotesService.deleteCategory(category.id);
      await _reload();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update categories. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Note categories'),
      content: SizedBox(
        width: 420,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 430),
          child: _categories.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 38,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 10),
                      const Text('No categories yet'),
                      const SizedBox(height: 4),
                      Text(
                        'Create one to organize your reminders.',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: colors.secondaryContainer,
                        child: Icon(
                          Icons.label_outline,
                          size: 17,
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                      title: Text(category.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Rename ${category.name}',
                            onPressed: _busy ? null : () => _rename(category),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete ${category.name}',
                            onPressed: _busy ? null : () => _delete(category),
                            icon: Icon(
                              Icons.delete_outline,
                              color: colors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Done'),
        ),
        FilledButton.icon(
          onPressed: _busy ? null : _create,
          icon: const Icon(Icons.add),
          label: const Text('Add category'),
        ),
      ],
    );
  }
}
