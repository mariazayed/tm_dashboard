import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/invest/journal_model.dart';
import '../../models/invest/learning_model.dart';
import '../../services/learning_service.dart';
import '../../widgets/md_editor_field.dart';
import 'invest_ui.dart';
import 'learning_sheets.dart';

/// What you have learned: searchable, filterable by source and tag.
class LearningNotesTab extends StatefulWidget {
  const LearningNotesTab({super.key, LearningService? service})
    : _service = service;

  final LearningService? _service;

  @override
  State<LearningNotesTab> createState() => _LearningNotesTabState();
}

class _LearningNotesTabState extends State<LearningNotesTab> {
  final _search = TextEditingController();
  Timer? _debounce;
  final _notes = <LearningNoteModel>[];
  List<LearningSourceModel> _sources = const [];
  List<JournalTagModel> _tags = const [];
  int? _sourceId;
  String? _tag;
  int _page = 0;
  int _total = 0;
  bool _hasMore = false;
  bool _loading = true;
  String? _error;
  int _generation = 0;

  LearningService get _service => widget._service ?? LearningService.shared;

  @override
  void initState() {
    super.initState();
    _reload();
    _loadFilters();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    try {
      final results = await Future.wait([
        _service.sources(),
        _service.noteTags(),
      ]);
      if (!mounted) return;
      setState(() {
        _sources = results[0] as List<LearningSourceModel>;
        _tags = results[1] as List<JournalTagModel>;
      });
    } catch (_) {
      // Filters are optional; the list still works without them.
    }
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    await _fetch(generation, page: 0, replace: true);
  }

  Future<void> _loadMore() =>
      _fetch(++_generation, page: _page + 1, replace: false);

  Future<void> _fetch(
    int generation, {
    required int page,
    required bool replace,
  }) async {
    try {
      final result = await _service.notes(
        sourceId: _sourceId,
        tag: _tag,
        query: _search.text,
        page: page,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        if (replace) _notes.clear();
        _notes.addAll(result.items);
        _page = result.page;
        _total = result.total;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } catch (e) {
      final message = await describeInvestError(e);
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = message;
        _loading = false;
      });
    }
  }

  Future<void> _openNote({LearningNoteModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NoteSheet(
        existing: existing,
        sources: _sources,
        suggestions: _tags.map((t) => t.name).toList(),
        service: widget._service,
      ),
    );
    if (saved == true) {
      _reload();
      _loadFilters();
    }
  }

  Future<void> _addCard(LearningNoteModel note) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CardSheet(
        noteId: note.id,
        initialFront: '',
        service: widget._service,
      ),
    );
    if (saved == true && mounted) showToast(context, 'Flashcard added');
  }

  Future<void> _delete(LearningNoteModel note) async {
    final ok = await confirmDelete(
      context,
      title: 'Delete note?',
      message: '"${note.title}" will be removed. Its flashcards are kept.',
    );
    if (!ok) return;
    try {
      await _service.deleteNote(note.id);
      _reload();
      _loadFilters();
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) showToast(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const Key('add-note'),
            onPressed: () => _openNote(),
            icon: const Icon(Icons.add),
            label: const Text('New note'),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('notes-search'),
          controller: _search,
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 400), _reload);
          },
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search your notes',
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: [
            if (_sources.isNotEmpty)
              _filter(
                DropdownButton<int?>(
                  key: const Key('source-filter'),
                  isExpanded: true,
                  value: _sourceId,
                  hint: const Text('Source'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Any source'),
                    ),
                    for (final s in _sources)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text(s.title, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() => _sourceId = v);
                    _reload();
                  },
                ),
              ),
            if (_tags.isNotEmpty)
              _filter(
                DropdownButton<String?>(
                  key: const Key('note-tag-filter'),
                  isExpanded: true,
                  value: _tag,
                  hint: const Text('Tag'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any tag')),
                    for (final t in _tags)
                      DropdownMenuItem(
                        value: t.name,
                        child: Text(
                          '#${t.name} (${t.count})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() => _tag = v);
                    _reload();
                  },
                ),
              ),
          ],
        ),
        Expanded(child: _body(theme)),
      ],
    );
  }

  /// Dropdowns inside a Wrap have no width of their own, so a long title would
  /// overflow a phone-width row; give each a ceiling instead.
  Widget _filter(Widget dropdown) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 200),
    child: dropdown,
  );

  Widget _body(ThemeData theme) {
    if (_loading && _notes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _notes.isEmpty) return Center(child: Text(_error!));
    if (_notes.isEmpty) {
      final filtered =
          _search.text.trim().isNotEmpty || _sourceId != null || _tag != null;
      return Center(
        child: Text(
          key: const Key('notes-empty'),
          filtered
              ? 'Nothing matches those filters'
              : 'No notes yet. Write down one thing you learned.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView(
      children: [
        Text('$_total ${_total == 1 ? 'note' : 'notes'}'),
        for (final n in _notes)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: InkWell(
              key: ValueKey('note-${n.id}'),
              onTap: () => _openNote(existing: n),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Make a flashcard',
                          icon: const Icon(Icons.style_outlined),
                          onPressed: () => _addCard(n),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(n),
                        ),
                      ],
                    ),
                    if (n.sourceTitle != null)
                      Text(
                        'From ${n.sourceTitle}',
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 6),
                    buildMarkdownPreview(context, n.body),
                    if (n.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: [
                          for (final t in n.tags)
                            Text('#$t', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (_hasMore)
          Center(
            child: TextButton(
              key: const Key('notes-load-more'),
              onPressed: _loadMore,
              child: const Text('Load more'),
            ),
          ),
      ],
    );
  }
}
