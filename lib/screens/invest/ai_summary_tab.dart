import 'package:flutter/material.dart';

import '../../models/invest/checkin_summary_model.dart';
import '../../models/invest/journal_model.dart';
import '../../models/invest/plan_model.dart';
import '../../services/plan_service.dart';
import 'ai_context_dialog.dart';
import 'invest_ui.dart';
import 'journal_entry_sheet.dart';

/// Summary: a month's facts (plain arithmetic, always shown, nothing sent
/// anywhere) and, only when asked for, an AI-worded draft of a check-in.
/// The draft is never saved: "Use in check-in" opens an entry you can edit.
class AiSummaryTab extends StatefulWidget {
  const AiSummaryTab({super.key, PlanService? service, this.now})
    : _service = service;

  final PlanService? _service;

  /// For tests; defaults to the current time.
  final DateTime Function()? now;

  @override
  State<AiSummaryTab> createState() => _AiSummaryTabState();
}

class _AiSummaryTabState extends State<AiSummaryTab> {
  static const _monthCount = 6;

  late String _month;
  bool _includeJournal = true;
  bool _busy = false;
  AiStatusModel? _status;
  CheckinSummaryModel? _result;
  String? _error;
  // A late answer for a month that was replaced must not appear.
  int _generation = 0;

  PlanService get _service => widget._service ?? PlanService.shared;
  DateTime get _today => (widget.now ?? DateTime.now)();

  /// This month and the five before it, newest first, as yyyy-MM.
  List<String> get _months {
    final t = _today;
    return [
      for (var i = 0; i < _monthCount; i++)
        _format(DateTime(t.year, t.month - i)),
    ];
  }

  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _month = _months.first;
    _loadStatus();
    _load(false);
  }

  Future<void> _loadStatus() async {
    try {
      final status = await _service.aiStatus();
      if (mounted) setState(() => _status = status);
    } catch (_) {}
  }

  bool get _aiReady => _status?.configured ?? false;

  /// [withAi] false loads just the facts; nothing is sent to the provider.
  Future<void> _load(bool withAi) async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await _service.checkinSummary(
        month: _month,
        includeModel: withAi,
        includeJournal: _includeJournal,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _result = result;
        _busy = false;
      });
    } catch (e) {
      final message = await describeInvestError(e);
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = message;
        _result = null;
        _busy = false;
      });
    }
  }

  Future<void> _preview() => showDialog<void>(
    context: context,
    builder: (_) => AiContextDialog(
      service: _service,
      summaryMonth: _month,
      includeJournal: _includeJournal,
    ),
  );

  Future<void> _use(CheckinSummaryModel r) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => JournalEntrySheet(
      initialType: JournalEntryType.checkin,
      initialBody: r.text ?? '',
      contributionId: r.contributionId,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = _result;
    final info = r?.model;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Monthly summary', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'The facts of a month, worked out from your own records. '
              'Nothing here is saved or changed.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              key: const Key('summary-month'),
              value: _month,
              items: [
                for (final m in _months)
                  DropdownMenuItem(value: m, child: Text(m)),
              ],
              onChanged: _busy
                  ? null
                  : (m) {
                      if (m == null || m == _month) return;
                      setState(() {
                        _month = m;
                        _result = null;
                      });
                      _load(false);
                    },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  key: const Key('summary-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (r != null) ...[
              const SizedBox(height: 8),
              Text('Facts', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              for (var i = 0; i < r.factsLines.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(r.factsLines[i], key: Key('fact-$i')),
                ),
            ] else if (_busy && _error == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            const Divider(height: 32),
            Text('Draft with AI', style: theme.textTheme.titleMedium),
            SwitchListTile(
              key: const Key('summary-journal-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Include my journal entries'),
              subtitle: Text(
                _aiReady
                    ? 'Sends the month\'s facts and, with this on, the text of '
                          'your recent journal entries to the AI provider. '
                          'Nothing is sent until you ask for a draft.'
                    : 'Not available. ${_status?.reason ?? 'Checking whether the server is set up for AI.'}',
                key: const Key('summary-ai-note'),
              ),
              value: _includeJournal,
              onChanged: _aiReady && !_busy
                  ? (v) => setState(() => _includeJournal = v)
                  : null,
            ),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(
                  key: const Key('summary-draft'),
                  onPressed: _aiReady && !_busy ? () => _load(true) : null,
                  child: Text(_busy ? 'Working…' : 'Write a draft with AI'),
                ),
                TextButton(
                  key: const Key('summary-preview'),
                  onPressed: _aiReady && !_busy ? _preview : null,
                  child: const Text('See what will be sent'),
                ),
              ],
            ),
            if (r != null && info != null && info.requested) ...[
              const SizedBox(height: 12),
              if (r.text == null)
                Text(
                  info.reason ?? 'No draft could be written.',
                  key: const Key('summary-reason'),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(r.text!, key: const Key('summary-text')),
                  ),
                ),
                if (r.sources.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      r.sources.length == 1
                          ? 'Drew on entry ${r.sources.first}'
                          : 'Drew on entries ${r.sources.join(', ')}',
                      key: const Key('summary-sources'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const Key('summary-use'),
                    onPressed: () => _use(r),
                    child: const Text('Use in check-in'),
                  ),
                ),
              ],
              if (info.entriesSkipped > 0)
                Text(
                  '${info.entriesSkipped} older '
                  '${info.entriesSkipped == 1 ? 'entry was' : 'entries were'} '
                  'left out.',
                  key: const Key('summary-skipped'),
                  style: theme.textTheme.bodySmall,
                ),
            ],
            const SizedBox(height: 16),
            Text(
              'Every number in a draft is checked against the facts above. '
              'AI can still be wrong; read it before you use it.',
              key: const Key('summary-disclaimer'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
