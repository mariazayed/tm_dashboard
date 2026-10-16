import 'package:flutter/material.dart';

import 'package:tm_dashboard/widgets/page_back_button.dart';

import '../../models/reminder_note_category_model.dart';
import '../../models/reminder_note_model.dart';
import '../../services/reminder_notes_service.dart';
import 'reminder_note_categories_dialog.dart';

class ReminderNotesScreen extends StatefulWidget {
  const ReminderNotesScreen({super.key});

  @override
  State<ReminderNotesScreen> createState() => _ReminderNotesScreenState();
}

class _ReminderNotesScreenState extends State<ReminderNotesScreen> {
  List<ReminderNoteModel> _notes = [];
  List<ReminderNoteCategoryModel> _categories = [];
  bool _loading = true;
  int? _filterCategoryId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ReminderNotesService.getAllPaged(),
        ReminderNotesService.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _notes = results[0] as List<ReminderNoteModel>;
        _categories = results[1] as List<ReminderNoteCategoryModel>;
        if (_filterCategoryId != null &&
            !_categories.any((c) => c.id == _filterCategoryId)) {
          _filterCategoryId = null;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load reminder notes. Please try again.';
      });
    }
  }

  Future<void> _manageCategories() async {
    await showDialog<void>(
      context: context,
      builder: (_) => ReminderNoteCategoriesDialog(
        categories: _categories,
        onChanged: _load,
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _addNote() async {
    final result = await showModalBottomSheet<_NewNoteData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _AddReminderNoteSheet(categories: _categories),
    );
    if (result == null) return;
    try {
      await ReminderNotesService.create([
        ReminderNoteModel(
          id: 0,
          text: result.text,
          categoryId: result.categoryId,
        ).toJson(),
      ]);
      await _load();
    } catch (_) {
      if (mounted) {
        _showMessage('Could not save the note. Please try again.');
      }
    }
  }

  Future<void> _deleteNote(ReminderNoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This reminder note will be removed.'),
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
    try {
      await ReminderNotesService.delete(note.id);
      if (mounted) {
        setState(() => _notes.removeWhere((item) => item.id == note.id));
      }
    } catch (_) {
      if (mounted) _showMessage('Could not delete the note. Please try again.');
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filterCategoryId == null
        ? _notes
        : _filterCategoryId == -1
        ? _notes.where((note) => note.categoryId == null).toList()
        : _notes.where((note) => note.categoryId == _filterCategoryId).toList();
    return Scaffold(
      appBar: AppBar(
        leading: const PageBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Reminder Notes'),
        actions: [
          IconButton(
            tooltip: 'Manage categories',
            onPressed: _manageCategories,
            icon: const Icon(Icons.category_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        icon: const Icon(Icons.add),
        label: const Text('New note'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Notes are unavailable',
              subtitle: _error!,
              action: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep useful reminders close at hand.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text('All notes  ${_notes.length}'),
                                    selected: _filterCategoryId == null,
                                    onSelected: (_) => setState(
                                      () => _filterCategoryId = null,
                                    ),
                                  ),
                                ),
                                ..._categories.map((category) {
                                  final count = _notes
                                      .where((n) => n.categoryId == category.id)
                                      .length;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text('${category.name}  $count'),
                                      selected:
                                          _filterCategoryId == category.id,
                                      onSelected: (_) => setState(
                                        () => _filterCategoryId = category.id,
                                      ),
                                    ),
                                  );
                                }),
                                if (_notes.any((n) => n.categoryId == null))
                                  ChoiceChip(
                                    label: Text(
                                      'Uncategorized  ${_notes.where((n) => n.categoryId == null).length}',
                                    ),
                                    selected: _filterCategoryId == -1,
                                    onSelected: (_) =>
                                        setState(() => _filterCategoryId = -1),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        icon: _notes.isEmpty
                            ? Icons.sticky_note_2_outlined
                            : Icons.filter_alt_off_outlined,
                        title: _notes.isEmpty
                            ? 'No reminders yet'
                            : 'No notes in this category',
                        subtitle: _notes.isEmpty
                            ? 'Add a note to keep an important reminder within reach.'
                            : 'Choose another category or add a note here.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      sliver: SliverList.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final note = filtered[index];
                          return Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 2,
                                      right: 14,
                                    ),
                                    child: Icon(
                                      Icons.push_pin_outlined,
                                      size: 19,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (note.categoryName != null &&
                                            note.categoryName!.isNotEmpty) ...[
                                          _CategoryBadge(
                                            label: note.categoryName!,
                                          ),
                                          const SizedBox(height: 9),
                                        ],
                                        SelectableText(
                                          note.text,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(height: 1.45),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete note',
                                    onPressed: () => _deleteNote(note),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: colors.primary),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            if (action != null) ...[const SizedBox(height: 10), action!],
          ],
        ),
      ),
    );
  }
}

class _NewNoteData {
  const _NewNoteData(this.text, this.categoryId);
  final String text;
  final int? categoryId;
}

class _AddReminderNoteSheet extends StatefulWidget {
  const _AddReminderNoteSheet({required this.categories});
  final List<ReminderNoteCategoryModel> categories;
  @override
  State<_AddReminderNoteSheet> createState() => _AddReminderNoteSheetState();
}

class _AddReminderNoteSheetState extends State<_AddReminderNoteSheet> {
  final _controller = TextEditingController();
  int? _categoryId;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New reminder', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'What do you want to remember?',
              prefixIcon: Icon(Icons.edit_note_outlined),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int?>(
            initialValue: _categoryId,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.sell_outlined),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Uncategorized'),
              ),
              ...widget.categories.map(
                (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (id) => setState(() => _categoryId = id),
          ),
          if (widget.categories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'You can create categories from the category icon on this page.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              final text = _controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context, _NewNoteData(text, _categoryId));
            },
            icon: const Icon(Icons.add),
            label: const Text('Save note'),
          ),
        ],
      ),
    );
  }
}
