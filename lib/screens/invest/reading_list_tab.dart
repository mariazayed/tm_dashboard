import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/invest/learning_model.dart';
import '../../services/learning_service.dart';
import 'invest_ui.dart';
import 'learning_sheets.dart';

/// Books, videos, articles and podcasts, grouped by progress.
class ReadingListTab extends StatefulWidget {
  const ReadingListTab({super.key, LearningService? service})
    : _service = service;

  final LearningService? _service;

  @override
  State<ReadingListTab> createState() => _ReadingListTabState();
}

class _ReadingListTabState extends State<ReadingListTab> {
  List<LearningSourceModel> _sources = const [];
  bool _loading = true;
  String? _error;

  LearningService get _service => widget._service ?? LearningService.shared;

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
      final sources = await _service.sources();
      if (mounted) {
        setState(() {
          _sources = sources;
          _loading = false;
        });
      }
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) {
        setState(() {
          _error = message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _openSheet({LearningSourceModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SourceSheet(existing: existing, service: widget._service),
    );
    if (saved == true) _load();
  }

  Future<void> _setStatus(
    LearningSourceModel source,
    SourceStatus status,
  ) async {
    try {
      await _service.updateSource(source.id, source.toRequest(status: status));
      _load();
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) showToast(context, message);
    }
  }

  Future<void> _delete(LearningSourceModel source) async {
    final ok = await confirmDelete(
      context,
      title: 'Remove from reading list?',
      message:
          '"${source.title}" will be removed. Notes that came from it are kept.',
    );
    if (!ok) return;
    try {
      await _service.deleteSource(source.id);
      _load();
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) showToast(context, message);
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static IconData _icon(SourceType t) => switch (t) {
    SourceType.book => Icons.menu_book_outlined,
    SourceType.video => Icons.play_circle_outline,
    SourceType.article => Icons.article_outlined,
    SourceType.podcast => Icons.headphones_outlined,
    SourceType.other => Icons.bookmark_border,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            key: const Key('add-source'),
            onPressed: () => _openSheet(),
            icon: const Icon(Icons.add),
            label: const Text('Add to reading list'),
          ),
        ),
        if (_sources.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              key: Key('reading-empty'),
              child: Text(
                'Nothing here yet. Add the book, video or article you are learning from.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        for (final status in [
          SourceStatus.inProgress,
          SourceStatus.todo,
          SourceStatus.done,
        ])
          ..._group(theme, status),
      ],
    );
  }

  List<Widget> _group(ThemeData theme, SourceStatus status) {
    final items = _sources.where((s) => s.status == status).toList();
    if (items.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
        child: Text(
          '${status.label} (${items.length})',
          key: ValueKey('group-${status.api}'),
          style: theme.textTheme.titleSmall,
        ),
      ),
      for (final s in items)
        Card(
          child: ListTile(
            key: ValueKey('source-${s.id}'),
            leading: Icon(_icon(s.sourceType)),
            title: Text(s.title),
            subtitle: Text(
              [s.sourceType.label, if (s.notes != null) s.notes!].join(' · '),
            ),
            onTap: s.url == null ? null : () => _open(s.url!),
            trailing: PopupMenuButton<String>(
              key: ValueKey('source-menu-${s.id}'),
              onSelected: (v) {
                switch (v) {
                  case 'edit':
                    _openSheet(existing: s);
                  case 'delete':
                    _delete(s);
                  default:
                    _setStatus(s, SourceStatus.fromApi(v));
                }
              },
              itemBuilder: (_) => [
                for (final next in SourceStatus.values)
                  if (next != s.status)
                    PopupMenuItem(
                      value: next.api,
                      child: Text('Mark ${next.label.toLowerCase()}'),
                    ),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        ),
    ];
  }
}
