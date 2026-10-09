import 'package:flutter/material.dart';

import '../../models/invest/journal_model.dart';
import '../../models/invest/tag_suggestion_model.dart';
import '../../services/contribution_service.dart';
import '../../services/journal_service.dart';
import '../../services/plan_service.dart';
import '../../widgets/md_editor_field.dart';
import 'invest_ui.dart';
import 'tag_input.dart';

/// Write or edit one journal entry. Used for quick capture (a few taps), the
/// pre-filled monthly check-in, decisions and edits.
class JournalEntrySheet extends StatefulWidget {
  const JournalEntrySheet({
    super.key,
    this.existing,
    this.initialType = JournalEntryType.quick,
    this.initialBody = '',
    this.contributionId,
    this.suggestions = const [],
    JournalService? service,
    PlanService? planService,
  }) : _service = service,
       _planService = planService;

  final JournalEntryModel? existing;
  final JournalEntryType initialType;
  final String initialBody;

  /// The buy this entry is about (set by the monthly check-in).
  final int? contributionId;
  final List<String> suggestions;
  final JournalService? _service;
  final PlanService? _planService;

  @override
  State<JournalEntrySheet> createState() => _JournalEntrySheetState();
}

class _JournalEntrySheetState extends State<JournalEntrySheet> {
  late final TextEditingController _body;
  late JournalEntryType _type;
  int? _mood;
  late List<String> _tags;
  List<TagSuggestionModel> _suggested = const [];
  bool _suggesting = false;
  String? _suggestNote;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;
  JournalService get _service => widget._service ?? JournalService.shared;
  PlanService get _planService => widget._planService ?? PlanService.shared;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _body = TextEditingController(text: e?.body ?? widget.initialBody);
    _type = e?.entryType ?? widget.initialType;
    _mood = e?.mood;
    _tags = [...?e?.tags];
    // A check-in starts with the tag you will almost always want.
    if (e == null && _type == JournalEntryType.checkin) _tags = ['check-in'];
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  /// Asks the AI for tags on the current draft. Nothing is added until a chip
  /// is tapped, and nothing is stored until the entry is saved.
  Future<void> _suggestTags() async {
    if (_suggesting) return;
    if (_body.text.trim().isEmpty) {
      setState(() => _suggestNote = 'Write something first');
      return;
    }
    setState(() {
      _suggesting = true;
      _suggestNote = null;
    });
    try {
      final result = await _planService.tagSuggestions(
        body: _body.text,
        entryType: _type.api,
        mood: _mood,
        existingTags: _tags,
      );
      if (!mounted) return;
      setState(() {
        _suggested = result.where((s) => !_tags.contains(s.tag)).toList();
        _suggestNote = _suggested.isEmpty
            ? 'No tag suggestions this time'
            : null;
      });
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) setState(() => _suggestNote = message);
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  void _takeSuggestion(TagSuggestionModel s) {
    setState(() {
      if (!_tags.contains(s.tag) && _tags.length < 10) {
        _tags = [..._tags, s.tag];
      }
      _suggested = _suggested.where((x) => x.tag != s.tag).toList();
    });
  }

  Future<void> _save() async {
    if (_body.text.trim().isEmpty) {
      setState(() => _error = 'Write something first');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final payload = {
      'entryType': _type.api,
      'mood': _mood,
      'body': _body.text,
      'tags': _tags,
      'contributionId':
          widget.existing?.contributionId ?? widget.contributionId,
    };
    try {
      if (_isEdit) {
        await _service.update(widget.existing!.id, payload);
      } else {
        await _service.create(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } on InvestApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not reach the server');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEdit ? 'Edit entry' : 'New entry',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<JournalEntryType>(
              key: const Key('type-toggle'),
              showSelectedIcon: false,
              segments: [
                for (final t in JournalEntryType.values)
                  ButtonSegment(value: t, label: Text(t.label)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            Text(
              'How do you feel? (optional)',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                for (final entry in JournalEntryModel.moodLabels.entries)
                  ChoiceChip(
                    key: ValueKey('mood-${entry.key}'),
                    label: Text('${entry.key}'),
                    tooltip: entry.value,
                    selected: _mood == entry.key,
                    // Tap the selected mood again to clear it.
                    onSelected: (on) =>
                        setState(() => _mood = on ? entry.key : null),
                  ),
              ],
            ),
            if (_mood != null)
              Text(
                JournalEntryModel.moodLabels[_mood]!,
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            MdEditorField(label: 'Note', controller: _body, minLines: 5),
            TagInput(
              tags: _tags,
              suggestions: widget.suggestions,
              onChanged: (t) => setState(() => _tags = t),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('suggest-tags'),
                onPressed: _suggesting || _saving ? null : _suggestTags,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(_suggesting ? 'Thinking…' : 'Suggest tags'),
              ),
            ),
            if (_suggested.isNotEmpty)
              Wrap(
                spacing: 8,
                children: [
                  for (final s in _suggested)
                    Tooltip(
                      message: s.reason,
                      child: ActionChip(
                        key: Key('suggested-${s.tag}'),
                        avatar: const Icon(Icons.add, size: 16),
                        label: Text(s.isNew ? '${s.tag} (new)' : s.tag),
                        onPressed: () => _takeSuggestion(s),
                      ),
                    ),
                ],
              ),
            if (_suggestNote != null)
              Text(
                _suggestNote!,
                key: const Key('suggest-note'),
                style: theme.textTheme.bodySmall,
              ),
            Text(
              'Suggest tags sends this note and the names of your tags to the AI provider. '
              'Nothing is added until you tap a tag.',
              key: const Key('suggest-privacy'),
              style: theme.textTheme.bodySmall,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  key: const Key('form-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
