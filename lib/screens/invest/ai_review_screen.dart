import 'package:flutter/material.dart';

import '../../models/invest/journal_model.dart';
import '../../models/invest/plan_model.dart';
import '../../models/invest/rule_check_model.dart';
import '../../services/plan_service.dart';
import 'ai_context_dialog.dart';
import 'ai_summary_tab.dart';
import 'invest_ui.dart';
import 'journal_entry_sheet.dart';

/// The rule check half of Review: checks a stretch of your journal and plan against your own rules.
/// The exact checks are plain code and always run. The AI reading is a
/// separate choice, off until you switch it on, and it only ever suggests:
/// nothing here changes or marks an entry.
class AiReviewScreen extends StatelessWidget {
  const AiReviewScreen({super.key, PlanService? service, this.now})
    : _service = service;

  final PlanService? _service;

  /// For tests; defaults to the current time.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(key: Key('review-tab-rules'), text: 'Rule check'),
              Tab(key: Key('review-tab-summary'), text: 'Summary'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                RuleCheckTab(service: _service, now: now),
                AiSummaryTab(service: _service, now: now),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RuleCheckTab extends StatefulWidget {
  const RuleCheckTab({super.key, PlanService? service, this.now})
    : _service = service;

  final PlanService? _service;

  /// For tests; defaults to the current time.
  final DateTime Function()? now;

  @override
  State<RuleCheckTab> createState() => _RuleCheckTabState();
}

class _RuleCheckTabState extends State<RuleCheckTab> {
  static const _ranges = [7, 30, 90];

  int _days = 30;
  bool _withAi = false;
  bool _showLow = false;
  bool _busy = false;
  AiStatusModel? _status;
  RuleCheckModel? _result;
  List<RuleModel> _rules = const [];
  String? _error;
  // A late answer for a run that was replaced must not appear.
  int _generation = 0;

  PlanService get _service => widget._service ?? PlanService.shared;
  DateTime get _today => (widget.now ?? DateTime.now)();
  DateTime get _from => _today.subtract(Duration(days: _days - 1));

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  /// Best effort: without it the AI switch just stays off.
  Future<void> _loadStatus() async {
    try {
      final status = await _service.aiStatus();
      if (mounted) setState(() => _status = status);
    } catch (_) {}
  }

  bool get _aiReady => _status?.configured ?? false;

  Future<void> _run() async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final withAi = _withAi && _aiReady;
      final result = await _service.ruleCheck(
        from: _from,
        to: _today,
        includeModel: withAi,
      );
      var rules = _rules;
      if (result.findings.any((f) => f.isModel)) {
        try {
          rules = await _service.rules();
        } catch (_) {} // rule numbers are a nicety
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _result = result;
        _rules = rules;
        _showLow = false;
        _busy = false;
      });
    } catch (e) {
      final message = await describeInvestError(e);
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = message;
        _busy = false;
      });
    }
  }

  Future<void> _preview() => showDialog<void>(
    context: context,
    builder: (_) =>
        AiContextDialog(service: _service, checkFrom: _from, checkTo: _today),
  );

  Future<void> _reflect(RuleFindingModel finding) async {
    final rule = _ruleFor(finding);
    final body = StringBuffer('I noticed: ${finding.message}\n');
    if (rule != null) body.write('The rule says: ${rule.text}\n');
    body.write('What I will do next time: ');
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => JournalEntrySheet(
        initialType: JournalEntryType.quick,
        initialBody: body.toString(),
      ),
    );
  }

  RuleModel? _ruleFor(RuleFindingModel f) {
    for (final r in _rules) {
      if (r.id == f.ruleId) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Review', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Check a stretch of your journal and plan against your own rules. '
              'Nothing here changes or marks an entry.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final d in _ranges)
                  ChoiceChip(
                    key: Key('range-$d'),
                    label: Text('Last $d days'),
                    selected: _days == d,
                    onSelected: _busy ? null : (_) => setState(() => _days = d),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              key: const Key('review-ai-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Also let AI read the journal'),
              subtitle: Text(
                _aiReady
                    ? 'Sends your rules and the text of the journal entries in '
                          'this range to the AI provider. Off by default.'
                    : 'Not available. ${_status?.reason ?? 'Checking whether the server is set up for AI.'}',
                key: const Key('review-ai-note'),
              ),
              value: _withAi && _aiReady,
              onChanged: _aiReady && !_busy
                  ? (v) => setState(() => _withAi = v)
                  : null,
            ),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton(
                  key: const Key('review-run'),
                  onPressed: _busy ? null : _run,
                  child: Text(_busy ? 'Checking…' : 'Run check'),
                ),
                TextButton(
                  key: const Key('review-preview'),
                  onPressed: _withAi && _aiReady && !_busy ? _preview : null,
                  child: const Text('See what will be sent'),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  key: const Key('review-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (_result != null) ..._results(theme, _result!),
            const SizedBox(height: 16),
            Text(
              'AI can be wrong. These are prompts to look, not verdicts.',
              key: const Key('review-disclaimer'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(ThemeData theme, RuleCheckModel r) {
    final exact = r.findings.where((f) => !f.isModel).toList();
    final model = r.findings.where((f) => f.isModel).toList();
    final visibleModel = model
        .where((f) => _showLow || f.confidence != 'LOW')
        .toList();
    final hiddenLow =
        model.length - model.where((f) => f.confidence != 'LOW').length;
    final info = r.model;
    return [
      const SizedBox(height: 16),
      Text('Exact checks', style: theme.textTheme.titleMedium),
      const SizedBox(height: 4),
      if (exact.isEmpty)
        const Text(
          'Nothing to flag. What you did lined up with your rules.',
          key: Key('review-exact-clear'),
        ),
      for (var i = 0; i < exact.length; i++)
        _FindingTile(
          key: Key('exact-$i'),
          finding: exact[i],
          onReflect: () => _reflect(exact[i]),
        ),
      for (final c in r.checks.where((c) => c.isOff))
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${c.label}: ${c.note ?? 'off'}',
            style: theme.textTheme.bodySmall,
          ),
        ),
      if (info != null && info.requested) ...[
        const SizedBox(height: 16),
        Text('AI reading', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        if (!info.ran)
          Text(
            info.reason ?? 'The AI reading did not run.',
            key: const Key('review-ai-reason'),
          )
        else ...[
          Text(
            'Read ${info.entriesChecked} journal '
            '${info.entriesChecked == 1 ? 'entry' : 'entries'}'
            '${info.entriesSkipped > 0 ? '. ${info.entriesSkipped} older '
                      '${info.entriesSkipped == 1 ? 'entry was' : 'entries were'} '
                      'left out; choose a shorter range to include them' : ''}.',
            key: const Key('review-ai-summary'),
            style: theme.textTheme.bodySmall,
          ),
          if (info.dropped > 0)
            Text(
              '${info.dropped} ${info.dropped == 1 ? 'suggestion was' : 'suggestions were'} '
              'discarded because ${info.dropped == 1 ? 'it' : 'they'} pointed at '
              'something that was not there.',
              key: const Key('review-ai-dropped'),
              style: theme.textTheme.bodySmall,
            ),
          const SizedBox(height: 4),
          if (model.isEmpty)
            const Text('No conflicts found.', key: Key('review-model-clear')),
          for (var i = 0; i < visibleModel.length; i++)
            _FindingTile(
              key: Key('model-$i'),
              finding: visibleModel[i],
              rule: _ruleFor(visibleModel[i]),
              rulePosition:
                  _rules.indexWhere((x) => x.id == visibleModel[i].ruleId) + 1,
              onReflect: () => _reflect(visibleModel[i]),
            ),
          if (hiddenLow > 0)
            TextButton(
              key: const Key('review-show-low'),
              onPressed: () => setState(() => _showLow = !_showLow),
              child: Text(
                _showLow
                    ? 'Hide low-confidence suggestions'
                    : 'Show $hiddenLow low-confidence '
                          '${hiddenLow == 1 ? 'suggestion' : 'suggestions'}',
              ),
            ),
        ],
      ],
    ];
  }
}

class _FindingTile extends StatelessWidget {
  const _FindingTile({
    super.key,
    required this.finding,
    required this.onReflect,
    this.rule,
    this.rulePosition = 0,
  });

  final RuleFindingModel finding;
  final VoidCallback onReflect;
  final RuleModel? rule;
  final int rulePosition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(finding.date, style: theme.textTheme.labelMedium),
                if (finding.isModel)
                  Chip(
                    key: const Key('confidence'),
                    label: Text('${finding.confidence} confidence'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (rule != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Rule ${rulePosition > 0 ? '$rulePosition: ' : ''}${rule!.text}',
                  key: const Key('finding-rule'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 4),
            Text(finding.message),
            if (finding.quote != null)
              Container(
                key: const Key('finding-quote'),
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: theme.colorScheme.outline,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  '“${finding.quote}”',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            if (finding.entryIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  finding.entryIds.length == 1
                      ? 'Entry ${finding.entryIds.first}'
                      : 'Entries ${finding.entryIds.join(', ')}',
                  key: const Key('finding-entries'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('add-reflection'),
                onPressed: onReflect,
                child: const Text('Add a reflection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
