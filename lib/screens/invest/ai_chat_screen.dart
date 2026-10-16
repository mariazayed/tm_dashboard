import 'package:flutter/material.dart';
import 'package:tm_dashboard/widgets/page_back_button.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../constants/route_names.dart';
import '../../models/invest/ai_chat_model.dart';
import '../../models/invest/plan_model.dart';
import '../../services/ai_chat_service.dart';
import '../../services/plan_service.dart';
import 'ai_context_dialog.dart';
import 'invest_ui.dart';

/// "Ask your journal": a read-only chat over your own rules, journal and
/// notes. It never changes anything; the answer cites the entries it used.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    super.key,
    AiChatService? service,
    PlanService? planService,
    this.onOpenSource,
  }) : _service = service,
       _planService = planService;

  final AiChatService? _service;
  final PlanService? _planService;

  /// Called by "Open" in the source dialog. Defaults to going to the Journal
  /// or Learning screen.
  final void Function(BuildContext context, ChatSource source)? onOpenSource;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _Message {
  _Message.user(this.text)
    : assistant = false,
      sources = const [],
      refusal = null,
      cutOff = false,
      truncated = false;

  _Message.assistant(ChatAnswer a)
    : assistant = true,
      text = a.answer,
      sources = a.sources,
      refusal = a.refusal,
      cutOff = a.cutOff,
      truncated = a.truncated;

  final bool assistant;
  final String text;
  final List<ChatSource> sources;
  final String? refusal;
  final bool cutOff;
  final bool truncated;

  /// A refused or empty answer is not fed back to the model, nor is the
  /// question that caused it.
  bool inHistory = true;
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <_Message>[];

  AiStatusModel? _status;
  AiUsageModel? _usage;
  String? _loadError;
  String? _error;
  bool _busy = false;
  bool _journal = true;
  bool _notes = true;
  // A late answer for a cancelled question must not appear.
  int _generation = 0;

  AiChatService get _service => widget._service ?? AiChatService.shared;
  PlanService get _plan => widget._planService ?? PlanService.shared;

  bool get _ready => _status?.configured ?? false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    _loadStatus();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => _loadError = null);
    try {
      final status = await _plan.aiStatus();
      if (!mounted) return;
      setState(() => _status = status);
      if (status.configured) _loadUsage();
    } catch (e) {
      final message = await describeInvestError(e);
      if (!mounted) return;
      setState(() => _loadError = message);
    }
  }

  /// Best effort: the chat works without the counter.
  Future<void> _loadUsage() async {
    try {
      final usage = await _service.usage();
      if (mounted) setState(() => _usage = usage);
    } catch (_) {}
  }

  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.isEmpty || _busy || !_ready) return;
    final history = ChatHistory.build([
      for (final m in _messages)
        if (m.inHistory) ChatTurn(assistant: m.assistant, text: m.text),
    ]);
    final generation = ++_generation;
    setState(() {
      _messages.add(_Message.user(question));
      _input.clear();
      _busy = true;
      _error = null;
    });
    _scrollToEnd();
    try {
      final answer = await _service.chat(
        question: question,
        history: history,
        includeJournal: _journal,
        includeNotes: _notes,
      );
      if (!mounted || generation != _generation) return;
      final reply = _Message.assistant(answer);
      if (answer.refused) {
        reply.inHistory = false;
        _messages.last.inHistory = false;
      }
      setState(() {
        _messages.add(reply);
        _busy = false;
      });
      _scrollToEnd();
      _loadUsage();
    } catch (e) {
      final message = await describeInvestError(e);
      if (!mounted || generation != _generation) return;
      // Give the question back so it can be sent again.
      setState(() {
        _messages.removeLast();
        _input.text = question;
        _error = message;
        _busy = false;
      });
    }
  }

  /// Stops waiting. The server may still finish the call, which still counts
  /// toward today's limit.
  void _cancel() {
    if (!_busy) return;
    final question = _messages.last.text;
    setState(() {
      _generation++;
      _messages.removeLast();
      _input.text = question;
      _busy = false;
    });
  }

  void _newChat() {
    setState(() {
      _generation++;
      _messages.clear();
      _error = null;
      _busy = false;
    });
  }

  Future<void> _preview() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AiContextDialog(
        service: _plan,
        question: _input.text.trim(),
        includeJournal: _journal,
        includeNotes: _notes,
      ),
    );
  }

  void _showSource(ChatSource source) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _SourceDialog(
        source: source,
        onOpen: () {
          Navigator.pop(dialogContext);
          final open = widget.onOpenSource ?? _openSource;
          open(context, source);
        },
      ),
    );
  }

  static void _openSource(BuildContext context, ChatSource source) {
    context.goNamed(
      source.isJournal ? RouteNames.investJournal : RouteNames.investLearning,
    );
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const PageBackButton(),
                  Expanded(
                    child: Text(
                      'Ask Your Journal',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  if (_messages.isNotEmpty)
                    TextButton(
                      key: const Key('chat-new'),
                      onPressed: _newChat,
                      child: const Text('New chat'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Questions are answered from your own rules, journal entries '
                'and learning notes. Nothing here changes your data.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Expanded(child: _body(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (_loadError != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_loadError!, key: const Key('chat-load-error')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _loadStatus, child: const Text('Retry')),
        ],
      );
    }
    if (_status == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_ready) _unavailable(theme),
        Expanded(
          child: _messages.isEmpty
              ? _emptyState(theme)
              : ListView.separated(
                  controller: _scroll,
                  itemCount: _messages.length + (_busy ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => i == _messages.length
                      ? _thinking(theme)
                      : _bubble(theme, _messages[i]),
                ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              key: const Key('chat-error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        _privacyRow(),
        _inputRow(),
        const SizedBox(height: 4),
        Text(
          'AI can be wrong. It does not give financial advice.',
          key: const Key('chat-disclaimer'),
          style: theme.textTheme.bodySmall,
        ),
        if (_usage != null)
          Text(
            'Today: ${_usage!.callsToday} of ${_usage!.dailyLimit} AI calls used.',
            key: const Key('chat-usage'),
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _unavailable(ThemeData theme) => Card(
    key: const Key('chat-unavailable'),
    color: theme.colorScheme.surfaceContainerHigh,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        'AI is not ready on the server. ${_status!.reason ?? ''}',
        style: theme.textTheme.bodyMedium,
      ),
    ),
  );

  Widget _emptyState(ThemeData theme) => Center(
    child: Text(
      _ready
          ? 'Try: "What did I write the last time the market dropped?" or '
                '"What are my rules about changing the plan?"'
          : '',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium,
    ),
  );

  Widget _thinking(ThemeData theme) => Row(
    key: const Key('chat-thinking'),
    children: [
      const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: 8),
      const Text('Reading your entries…'),
      const SizedBox(width: 8),
      TextButton(
        key: const Key('chat-cancel'),
        onPressed: _cancel,
        child: const Text('Cancel'),
      ),
    ],
  );

  Widget _bubble(ThemeData theme, _Message m) {
    final scheme = theme.colorScheme;
    final refused = m.refusal != null;
    final color = m.assistant
        ? (refused ? scheme.errorContainer : scheme.surfaceContainerHigh)
        : scheme.primaryContainer;
    return Align(
      alignment: m.assistant ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          key: Key(m.assistant ? 'answer' : 'question'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(m.text),
              if (m.sources.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final s in m.sources)
                      ActionChip(
                        key: Key('source-${s.handle}'),
                        avatar: Icon(
                          s.isJournal ? Icons.menu_book : Icons.school,
                          size: 16,
                        ),
                        label: Text(_chipLabel(s)),
                        onPressed: () => _showSource(s),
                      ),
                  ],
                ),
              ],
              if (m.cutOff)
                _note(
                  theme,
                  'The answer was cut short. Ask a narrower question.',
                ),
              if (m.truncated)
                _note(
                  theme,
                  'Some older material was left out to fit the size limit.',
                ),
              if (refused) _note(theme, 'This answer was replaced, not shown.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _note(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(text, style: theme.textTheme.bodySmall),
  );

  static String _chipLabel(ChatSource s) {
    final when = s.when;
    return when == null
        ? s.handle
        : '${s.handle} · ${DateFormat.MMMd().format(when)}';
  }

  Widget _privacyRow() => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      FilterChip(
        key: const Key('chat-privacy-journal'),
        label: const Text('Use journal'),
        selected: _journal,
        onSelected: (v) => setState(() => _journal = v),
      ),
      FilterChip(
        key: const Key('chat-privacy-notes'),
        label: const Text('Use notes'),
        selected: _notes,
        onSelected: (v) => setState(() => _notes = v),
      ),
      TextButton(
        key: const Key('chat-preview'),
        onPressed: _input.text.trim().isEmpty ? null : _preview,
        child: const Text('See what will be sent'),
      ),
    ],
  );

  Widget _inputRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: TextField(
          key: const Key('chat-input'),
          controller: _input,
          enabled: _ready && !_busy,
          minLines: 1,
          maxLines: 4,
          maxLength: 2000,
          decoration: const InputDecoration(
            hintText: 'Ask about your journal, notes or rules',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: IconButton.filled(
          key: const Key('chat-send'),
          tooltip: 'Send',
          onPressed: _ready && !_busy && _input.text.trim().isNotEmpty
              ? _send
              : null,
          icon: const Icon(Icons.send),
        ),
      ),
    ],
  );
}

/// The excerpt the assistant was shown for one source, read-only.
class _SourceDialog extends StatelessWidget {
  const _SourceDialog({required this.source, required this.onOpen});

  final ChatSource source;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final when = source.when;
    final date = when == null ? source.date : DateFormat.yMMMd().format(when);
    return AlertDialog(
      title: Text(
        '${source.isJournal ? 'Journal entry' : 'Learning note'} · $date',
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(source.snippet, key: const Key('source-text')),
              const SizedBox(height: 12),
              Text(
                'This is the excerpt the assistant saw. Long entries are cut.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          key: const Key('source-open'),
          onPressed: onOpen,
          child: Text(source.isJournal ? 'Open journal' : 'Open learning'),
        ),
      ],
    );
  }
}
