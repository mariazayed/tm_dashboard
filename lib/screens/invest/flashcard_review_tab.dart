import 'package:flutter/material.dart';

import '../../models/invest/learning_model.dart';
import '../../services/learning_service.dart';
import 'invest_ui.dart';
import 'learning_sheets.dart';

/// Today's spaced-repetition session, plus card management.
class FlashcardReviewTab extends StatefulWidget {
  const FlashcardReviewTab({super.key, LearningService? service})
    : _service = service;

  final LearningService? _service;

  @override
  State<FlashcardReviewTab> createState() => _FlashcardReviewTabState();
}

class _FlashcardReviewTabState extends State<FlashcardReviewTab> {
  CardStatsModel? _stats;
  List<FlashcardModel> _queue = const [];
  List<FlashcardModel>? _allCards;
  int _index = 0;
  bool _revealed = false;
  bool _busy = false;
  bool _loading = true;
  String? _error;
  String? _lastNext;

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
      final results = await Future.wait([
        _service.cardStats(),
        _service.dueCards(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as CardStatsModel;
        _queue = results[1] as List<FlashcardModel>;
        _index = 0;
        _revealed = false;
        _lastNext = null;
        _allCards = null;
        _loading = false;
      });
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

  Future<void> _grade(CardGrade grade) async {
    if (_busy) return;
    final card = _queue[_index];
    setState(() => _busy = true);
    try {
      final updated = await _service.review(card.id, grade);
      if (!mounted) return;
      setState(() {
        _lastNext =
            'Next review ${FlashcardModel.nextReviewText(updated.intervalDays)}';
        _index++;
        _revealed = false;
      });
      if (_index >= _queue.length) {
        // Refresh the counters now that the session is over.
        final stats = await _service.cardStats();
        if (mounted) setState(() => _stats = stats);
      }
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) showToast(context, message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openCard({FlashcardModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CardSheet(existing: existing, service: widget._service),
    );
    if (saved == true) _load();
  }

  Future<void> _deleteCard(FlashcardModel card) async {
    final ok = await confirmDelete(
      context,
      title: 'Delete flashcard?',
      message: 'This card and its review history will be removed.',
    );
    if (!ok) return;
    try {
      await _service.deleteCard(card.id);
      _load();
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) showToast(context, message);
    }
  }

  Future<void> _showAllCards() async {
    try {
      final cards = await _service.cards();
      if (mounted) setState(() => _allCards = cards);
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) showToast(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    final theme = Theme.of(context);
    final stats = _stats!;
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 8,
          children: [
            _Stat('Due today', '${stats.due}', key: const Key('stat-due')),
            _Stat('New', '${stats.newCards}'),
            _Stat('Reviewed today', '${stats.reviewedToday}'),
            _Stat('Total cards', '${stats.total}'),
          ],
        ),
        const SizedBox(height: 12),
        _session(theme, stats),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('add-card'),
              onPressed: () => _openCard(),
              icon: const Icon(Icons.add),
              label: const Text('Add card'),
            ),
            if (_allCards == null && stats.total > 0)
              TextButton(
                key: const Key('show-all-cards'),
                onPressed: _showAllCards,
                child: const Text('Manage all cards'),
              ),
          ],
        ),
        if (_allCards != null)
          for (final c in _allCards!)
            Card(
              child: ListTile(
                key: ValueKey('card-${c.id}'),
                title: Text(
                  c.front,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Due ${c.dueOn.toIso8601String().substring(0, 10)}',
                ),
                onTap: () => _openCard(existing: c),
                trailing: IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteCard(c),
                ),
              ),
            ),
      ],
    );
  }

  Widget _session(ThemeData theme, CardStatsModel stats) {
    if (stats.total == 0) {
      return const Center(
        key: Key('no-cards'),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No flashcards yet. Add one here, or tap the card icon on a note.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_queue.isEmpty || _index >= _queue.length) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline, size: 40),
              const SizedBox(height: 8),
              Text(
                _queue.isEmpty ? 'Nothing is due today' : 'All done for today',
                key: const Key('session-done'),
                style: theme.textTheme.titleMedium,
              ),
              if (_lastNext != null)
                Text(_lastNext!, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      );
    }
    final card = _queue[_index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Card ${_index + 1} of ${_queue.length}',
              key: const Key('session-progress'),
              style: theme.textTheme.bodySmall,
            ),
            if (_lastNext != null)
              Text(_lastNext!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            SelectableText(
              card.front,
              key: const Key('card-front-text'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (!_revealed)
              FilledButton(
                key: const Key('show-answer'),
                onPressed: () => setState(() => _revealed = true),
                child: const Text('Show answer'),
              )
            else ...[
              const Divider(),
              SelectableText(
                card.back,
                key: const Key('card-back-text'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final g in CardGrade.values)
                    g == CardGrade.good
                        ? FilledButton(
                            key: ValueKey('grade-${g.api}'),
                            onPressed: _busy ? null : () => _grade(g),
                            child: Text(g.label),
                          )
                        : OutlinedButton(
                            key: ValueKey('grade-${g.api}'),
                            onPressed: _busy ? null : () => _grade(g),
                            child: Text(g.label),
                          ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.headlineSmall),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
