import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/invest/journal_model.dart';
import '../../services/contribution_service.dart';
import '../../services/journal_service.dart';
import '../../widgets/md_editor_field.dart';
import 'journal_entry_sheet.dart';

/// Timeline of notes, check-ins and decisions with search and filters.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key, JournalService? service})
    : _service = service;

  final JournalService? _service;

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  final _entries = <JournalEntryModel>[];
  List<JournalTagModel> _tags = const [];
  JournalEntryType? _type;
  String? _tag;
  int _page = 0;
  int _total = 0;
  bool _hasMore = false;
  bool _loading = true;
  String? _error;
  // Guards against a slow response for old filters overwriting newer results.
  int _generation = 0;

  JournalService get _service => widget._service ?? JournalService.shared;

  @override
  void initState() {
    super.initState();
    _reload();
    _loadTags();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _reload);
  }

  Future<void> _loadTags() async {
    try {
      final tags = await _service.tags();
      if (mounted) setState(() => _tags = tags);
    } catch (_) {
      // Filtering by tag is optional; the timeline still works.
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

  Future<void> _loadMore() async {
    final generation = ++_generation;
    await _fetch(generation, page: _page + 1, replace: false);
  }

  Future<void> _fetch(
    int generation, {
    required int page,
    required bool replace,
  }) async {
    try {
      final result = await _service.list(
        tag: _tag,
        type: _type,
        query: _search.text,
        page: page,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        if (replace) _entries.clear();
        _entries.addAll(result.items);
        _page = result.page;
        _total = result.total;
        _hasMore = result.hasMore;
        _loading = false;
      });
    } on InvestApiException catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = 'Could not reach the server';
        _loading = false;
      });
    }
  }

  Future<void> _openSheet({
    JournalEntryModel? existing,
    JournalEntryType type = JournalEntryType.quick,
    String body = '',
    int? contributionId,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => JournalEntrySheet(
        existing: existing,
        initialType: type,
        initialBody: body,
        contributionId: contributionId,
        suggestions: _tags.map((t) => t.name).toList(),
        service: widget._service,
      ),
    );
    if (saved == true) {
      _reload();
      _loadTags();
    }
  }

  Future<void> _startCheckin() async {
    try {
      final template = await _service.checkinTemplate();
      if (!mounted) return;
      await _openSheet(
        type: JournalEntryType.checkin,
        body: template.body,
        contributionId: template.contributionId,
      );
    } on InvestApiException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Could not reach the server');
    }
  }

  Future<void> _confirmDelete(JournalEntryModel entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This note will be removed from your journal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.delete(entry.id);
      _reload();
      _loadTags();
    } on InvestApiException catch (e) {
      _toast(e.message);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Journal', style: theme.textTheme.headlineSmall),
              FilledButton.icon(
                onPressed: () => _openSheet(),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Quick note'),
              ),
              OutlinedButton(
                onPressed: _startCheckin,
                child: const Text('Monthly check-in'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('journal-search'),
            controller: _search,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search your notes',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _type == null,
                onSelected: (_) {
                  setState(() => _type = null);
                  _reload();
                },
              ),
              for (final t in JournalEntryType.values)
                ChoiceChip(
                  key: ValueKey('filter-${t.api}'),
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (on) {
                    setState(() => _type = on ? t : null);
                    _reload();
                  },
                ),
              if (_tags.isNotEmpty)
                DropdownButton<String?>(
                  key: const Key('tag-filter'),
                  value: _tag,
                  hint: const Text('Tag'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Any tag')),
                    for (final t in _tags)
                      DropdownMenuItem(
                        value: t.name,
                        child: Text('#${t.name} (${t.count})'),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() => _tag = v);
                    _reload();
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: _timeline(context)),
        ],
      ),
    );
  }

  Widget _timeline(BuildContext context) {
    if (_loading && _entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _entries.isEmpty) {
      return Center(child: Text(_error!));
    }
    if (_entries.isEmpty) {
      final filtered =
          _search.text.trim().isNotEmpty || _type != null || _tag != null;
      return Center(
        child: Text(
          key: const Key('journal-empty'),
          filtered
              ? 'Nothing matches those filters'
              : 'No entries yet. Capture a thought or do your monthly check-in.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView(
      children: [
        Text('$_total ${_total == 1 ? 'entry' : 'entries'}'),
        for (final e in _entries)
          _EntryCard(
            entry: e,
            onTap: () => _openSheet(existing: e),
            onDelete: () => _confirmDelete(e),
          ),
        if (_hasMore)
          Center(
            child: TextButton(
              key: const Key('load-more'),
              onPressed: _loadMore,
              child: const Text('Load more'),
            ),
          ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  final JournalEntryModel entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = DateFormat.yMMMd().add_jm().format(entry.createdAt);
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          label: Text(entry.entryType.label),
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(when, style: theme.textTheme.bodySmall),
                        if (entry.mood != null)
                          Text(
                            'Mood ${entry.mood}/5',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ],
              ),
              buildMarkdownPreview(context, entry.body),
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final t in entry.tags)
                      Text('#$t', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
