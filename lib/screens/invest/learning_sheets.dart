import 'package:flutter/material.dart';

import '../../models/invest/learning_model.dart';
import '../../services/contribution_service.dart';
import '../../services/learning_service.dart';
import '../../widgets/md_editor_field.dart';
import 'tag_input.dart';

/// Shared save plumbing: runs [action], closes the sheet on success and
/// reports a readable error otherwise.
mixin _SheetSaver<T extends StatefulWidget> on State<T> {
  bool saving = false;
  String? error;

  Future<void> runSave(Future<void> Function() action) async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await action();
      if (mounted) Navigator.pop(context, true);
    } on InvestApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'Could not reach the server');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget errorText(BuildContext context) => error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            error!,
            key: const Key('form-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
}

Widget _sheetFrame(BuildContext context, String title, List<Widget> children) {
  final bottom = MediaQuery.of(context).viewInsets.bottom;
  return SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

class SourceSheet extends StatefulWidget {
  const SourceSheet({super.key, this.existing, LearningService? service})
    : _service = service;

  final LearningSourceModel? existing;
  final LearningService? _service;

  @override
  State<SourceSheet> createState() => _SourceSheetState();
}

class _SourceSheetState extends State<SourceSheet> with _SheetSaver {
  late final TextEditingController _title;
  late final TextEditingController _url;
  late final TextEditingController _notes;
  late SourceType _type;
  late SourceStatus _status;

  LearningService get _service => widget._service ?? LearningService.shared;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _url = TextEditingController(text: e?.url ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _type = e?.sourceType ?? SourceType.book;
    _status = e?.status ?? SourceStatus.todo;
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => error = 'Give it a title');
      return;
    }
    final payload = {
      'title': _title.text.trim(),
      'sourceType': _type.api,
      'url': _url.text.trim().isEmpty ? null : _url.text.trim(),
      'status': _status.api,
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    };
    await runSave(
      () async => widget.existing == null
          ? await _service.createSource(payload)
          : await _service.updateSource(widget.existing!.id, payload),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _sheetFrame(
      context,
      widget.existing == null ? 'Add to reading list' : 'Edit source',
      [
        TextField(
          key: const Key('source-title'),
          controller: _title,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<SourceType>(
          key: const Key('source-type'),
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Type'),
          items: [
            for (final t in SourceType.values)
              DropdownMenuItem(value: t, child: Text(t.label)),
          ],
          onChanged: (v) => setState(() => _type = v ?? _type),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('source-url'),
          controller: _url,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Link (optional, http or https)',
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<SourceStatus>(
          key: const Key('source-status'),
          showSelectedIcon: false,
          segments: [
            for (final s in SourceStatus.values)
              ButtonSegment(value: s, label: Text(s.label)),
          ],
          selected: {_status},
          onSelectionChanged: (s) => setState(() => _status = s.first),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Notes (optional)'),
        ),
        errorText(context),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}

class NoteSheet extends StatefulWidget {
  const NoteSheet({
    super.key,
    this.existing,
    this.sources = const [],
    this.suggestions = const [],
    LearningService? service,
  }) : _service = service;

  final LearningNoteModel? existing;
  final List<LearningSourceModel> sources;
  final List<String> suggestions;
  final LearningService? _service;

  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends State<NoteSheet> with _SheetSaver {
  late final TextEditingController _title;
  late final TextEditingController _body;
  int? _sourceId;
  late List<String> _tags;

  LearningService get _service => widget._service ?? LearningService.shared;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _body = TextEditingController(text: e?.body ?? '');
    _sourceId = e?.sourceId;
    _tags = [...?e?.tags];
    // Keep the dropdown valid if the note points at a source that is gone.
    if (_sourceId != null && !widget.sources.any((s) => s.id == _sourceId)) {
      _sourceId = null;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      setState(() => error = 'A note needs a title and some text');
      return;
    }
    final payload = {
      'title': _title.text.trim(),
      'body': _body.text,
      'sourceId': _sourceId,
      'tags': _tags,
    };
    await runSave(
      () async => widget.existing == null
          ? await _service.createNote(payload)
          : await _service.updateNote(widget.existing!.id, payload),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _sheetFrame(
      context,
      widget.existing == null ? 'New learning note' : 'Edit note',
      [
        TextField(
          key: const Key('note-title'),
          controller: _title,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          key: const Key('note-source'),
          initialValue: _sourceId,
          decoration: const InputDecoration(labelText: 'From (optional)'),
          items: [
            const DropdownMenuItem(value: null, child: Text('No source')),
            for (final s in widget.sources)
              DropdownMenuItem(value: s.id, child: Text(s.title)),
          ],
          onChanged: (v) => setState(() => _sourceId = v),
        ),
        const SizedBox(height: 12),
        MdEditorField(label: 'Note', controller: _body, minLines: 6),
        TagInput(
          tags: _tags,
          suggestions: widget.suggestions,
          onChanged: (t) => setState(() => _tags = t),
        ),
        errorText(context),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}

class CardSheet extends StatefulWidget {
  const CardSheet({
    super.key,
    this.existing,
    this.noteId,
    this.initialFront = '',
    LearningService? service,
  }) : _service = service;

  final FlashcardModel? existing;

  /// The note this card is made from (new cards only; edits keep their link).
  final int? noteId;
  final String initialFront;
  final LearningService? _service;

  @override
  State<CardSheet> createState() => _CardSheetState();
}

class _CardSheetState extends State<CardSheet> with _SheetSaver {
  late final TextEditingController _front;
  late final TextEditingController _back;

  LearningService get _service => widget._service ?? LearningService.shared;

  @override
  void initState() {
    super.initState();
    _front = TextEditingController(
      text: widget.existing?.front ?? widget.initialFront,
    );
    _back = TextEditingController(text: widget.existing?.back ?? '');
  }

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_front.text.trim().isEmpty || _back.text.trim().isEmpty) {
      setState(() => error = 'Both sides of the card need text');
      return;
    }
    final payload = {
      'front': _front.text.trim(),
      'back': _back.text.trim(),
      'noteId': widget.existing?.noteId ?? widget.noteId,
    };
    await runSave(
      () async => widget.existing == null
          ? await _service.createCard(payload)
          : await _service.updateCard(widget.existing!.id, payload),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _sheetFrame(
      context,
      widget.existing == null ? 'New flashcard' : 'Edit flashcard',
      [
        TextField(
          key: const Key('card-front'),
          controller: _front,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Question (front)',
            hintText: 'What is dollar-cost averaging?',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('card-back'),
          controller: _back,
          minLines: 2,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Answer (back)'),
        ),
        errorText(context),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: saving ? null : _save,
          child: Text(saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
