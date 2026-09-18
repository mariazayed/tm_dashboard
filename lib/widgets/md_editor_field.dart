import 'package:flutter/material.dart';

/// A minimal write/preview markdown editor with no external dependency.
///
/// There's no markdown package in pubspec.yaml yet (flutter_markdown /
/// markdown_widget etc.), and this was written without a working `flutter
/// pub get` in hand to verify a new dependency resolves cleanly -- so this
/// renders a small, self-contained subset of markdown (headers `#`/`##`/
/// `###`, `**bold**`, `*italic*`, `` `code` ``, `-`/`*` bullet lists, `1.`
/// numbered lists, blank-line-separated paragraphs) directly with Flutter's
/// own widgets. Good enough for decision notes; swap in a real markdown
/// package later if richer rendering (tables, links, images...) is needed.
class MdEditorField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final int minLines;
  final int maxLines;

  const MdEditorField({
    super.key,
    required this.label,
    required this.controller,
    this.minLines = 4,
    this.maxLines = 14,
  });

  @override
  State<MdEditorField> createState() => _MdEditorFieldState();
}

class _MdEditorFieldState extends State<MdEditorField> {
  bool _preview = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              _ToggleButton(
                label: 'Write',
                selected: !_preview,
                onTap: () => setState(() => _preview = false),
              ),
              const SizedBox(width: 4),
              _ToggleButton(
                label: 'Preview',
                selected: _preview,
                onTap: () => setState(() => _preview = true),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: widget.minLines * 22.0,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: _preview
                ? (widget.controller.text.trim().isEmpty
                    ? Text('Nothing to preview yet', style: TextStyle(color: colorScheme.onSurfaceVariant))
                    : buildMarkdownPreview(context, widget.controller.text))
                : TextField(
                    controller: widget.controller,
                    minLines: widget.minLines,
                    maxLines: widget.maxLines,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: 'Markdown supported: # heading, **bold**, *italic*, - bullet, 1. numbered',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Renders [source] as a column of widgets covering the small markdown
/// subset described on [MdEditorField]. Exposed for reuse anywhere a
/// decision's markdown fields need to be shown read-only (detail sheets,
/// cards) without re-entering edit mode.
Widget buildMarkdownPreview(BuildContext context, String source, {TextStyle? baseStyle}) {
  final theme = Theme.of(context);
  final style = baseStyle ?? theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 13);
  final codeBackground = theme.colorScheme.surfaceContainerHigh;

  final lines = source.split('\n');
  final widgets = <Widget>[];
  var paragraph = <String>[];

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _richText(paragraph.join(' '), style, codeBackground),
      ),
    );
    paragraph = [];
  }

  for (final rawLine in lines) {
    final line = rawLine.trimRight();

    if (line.trim().isEmpty) {
      flushParagraph();
      continue;
    }

    final header = RegExp(r'^(#{1,3})\s+(.*)').firstMatch(line);
    if (header != null) {
      flushParagraph();
      final level = header.group(1)!.length;
      final size = level == 1 ? 18.0 : (level == 2 ? 16.0 : 14.0);
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Text(
            header.group(2)!,
            style: style.copyWith(fontSize: size, fontWeight: FontWeight.w700),
          ),
        ),
      );
      continue;
    }

    final bullet = RegExp(r'^[-*]\s+(.*)').firstMatch(line);
    if (bullet != null) {
      flushParagraph();
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: style),
              Expanded(child: _richText(bullet.group(1)!, style, codeBackground)),
            ],
          ),
        ),
      );
      continue;
    }

    final numbered = RegExp(r'^(\d+)\.\s+(.*)').firstMatch(line);
    if (numbered != null) {
      flushParagraph();
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${numbered.group(1)}.  ', style: style),
              Expanded(child: _richText(numbered.group(2)!, style, codeBackground)),
            ],
          ),
        ),
      );
      continue;
    }

    paragraph.add(line);
  }
  flushParagraph();

  if (widgets.isEmpty) {
    return Text(source, style: style);
  }

  return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: widgets);
}

/// Inline `**bold**` / `*italic*` / `` `code` `` spans within one line.
Widget _richText(String text, TextStyle baseStyle, Color codeBackground) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'(\*\*.+?\*\*|\*.+?\*|`.+?`)');
  var last = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > last) {
      spans.add(TextSpan(text: text.substring(last, match.start), style: baseStyle));
    }
    final token = match.group(0)!;
    if (token.startsWith('**')) {
      spans.add(TextSpan(
        text: token.substring(2, token.length - 2),
        style: baseStyle.copyWith(fontWeight: FontWeight.w700),
      ));
    } else if (token.startsWith('`')) {
      spans.add(TextSpan(
        text: token.substring(1, token.length - 1),
        style: baseStyle.copyWith(fontFamily: 'monospace', backgroundColor: codeBackground),
      ));
    } else {
      spans.add(TextSpan(
        text: token.substring(1, token.length - 1),
        style: baseStyle.copyWith(fontStyle: FontStyle.italic),
      ));
    }
    last = match.end;
  }

  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: baseStyle));
  }

  return RichText(text: TextSpan(children: spans, style: baseStyle));
}
