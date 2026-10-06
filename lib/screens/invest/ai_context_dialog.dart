import 'package:flutter/material.dart';

import '../../models/invest/plan_model.dart';
import '../../services/plan_service.dart';
import 'invest_ui.dart';

/// Shows, word for word, what an AI feature would be given about you, and lets
/// you switch the personal free text off to see the difference.
class AiContextDialog extends StatefulWidget {
  const AiContextDialog({super.key, PlanService? service}) : _service = service;

  final PlanService? _service;

  @override
  State<AiContextDialog> createState() => _AiContextDialogState();
}

class _AiContextDialogState extends State<AiContextDialog> {
  bool _journal = true;
  bool _notes = true;
  AiContextPreview? _preview;
  String? _error;
  bool _loading = true;
  // A slow answer for old switch settings must not overwrite a newer one.
  int _generation = 0;

  PlanService get _service => widget._service ?? PlanService.shared;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await _service.aiContext(
        includeJournal: _journal,
        includeNotes: _notes,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _preview = preview;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview;
    return AlertDialog(
      title: const Text('What an AI would see'),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is the exact text, built fresh from your data. Your reminder '
              'email and login details are never part of it.',
              style: theme.textTheme.bodySmall,
            ),
            SwitchListTile(
              key: const Key('include-journal'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Include recent journal entries'),
              value: _journal,
              onChanged: (v) {
                setState(() => _journal = v);
                _load();
              },
            ),
            SwitchListTile(
              key: const Key('include-notes'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Include recent learning notes'),
              value: _notes,
              onChanged: (v) {
                setState(() => _notes = v);
                _load();
              },
            ),
            if (preview != null && !_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${preview.characters} of ${preview.maxCharacters} characters'
                  '${preview.truncated ? ' (older entries were left out)' : ''}',
                  key: const Key('context-size'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            Flexible(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 120,
                  maxHeight: 360,
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Text(_error!, key: const Key('context-error'))
                    : SingleChildScrollView(
                        child: SelectableText(
                          preview!.text,
                          key: const Key('context-text'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
