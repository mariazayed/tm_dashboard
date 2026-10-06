import 'package:flutter/material.dart';

import '../../models/invest/journal_model.dart';

/// Chips for the chosen tags plus a text field that suggests existing ones.
/// Enter, a comma or tapping a suggestion adds a tag; tags are normalised
/// exactly as the server stores them.
class TagInput extends StatefulWidget {
  const TagInput({
    super.key,
    required this.tags,
    required this.suggestions,
    required this.onChanged,
    this.maxTags = 10,
  });

  final List<String> tags;
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;
  final int maxTags;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Adds every comma-separated tag in [raw], so "a, b" (typed or pasted) adds two.
  void _add(String raw) {
    _controller.clear();
    var tags = [...widget.tags];
    for (final part in raw.split(',')) {
      final tag = normalizeTag(part);
      if (tag == null || tag.length > 64) continue;
      if (tags.contains(tag) || tags.length >= widget.maxTags) continue;
      tags = [...tags, tag];
    }
    if (tags.length != widget.tags.length) {
      widget.onChanged(tags);
      _focus.requestFocus();
    }
  }

  void _remove(String tag) =>
      widget.onChanged(widget.tags.where((t) => t != tag).toList());

  @override
  Widget build(BuildContext context) {
    final full = widget.tags.length >= widget.maxTags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final t in widget.tags)
                InputChip(
                  key: ValueKey('tag-$t'),
                  label: Text('#$t'),
                  visualDensity: VisualDensity.compact,
                  onDeleted: () => _remove(t),
                ),
            ],
          ),
        RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focus,
          optionsBuilder: (value) {
            final q = normalizeTag(value.text);
            if (q == null) return const Iterable<String>.empty();
            return widget.suggestions.where(
              (s) => s.contains(q) && !widget.tags.contains(s),
            );
          },
          onSelected: _add,
          fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
              TextField(
                key: const Key('tag-field'),
                controller: controller,
                focusNode: focusNode,
                enabled: !full,
                decoration: InputDecoration(
                  labelText: full ? 'Tag limit reached' : 'Add a tag',
                  hintText: 'emotion, learning, market-event…',
                ),
                onChanged: (text) {
                  if (text.contains(',')) _add(text);
                },
                onSubmitted: _add,
              ),
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 180,
                  maxWidth: 320,
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final o in options)
                      ListTile(
                        dense: true,
                        title: Text('#$o'),
                        onTap: () => onSelected(o),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
