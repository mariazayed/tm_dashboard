import 'package:flutter/material.dart';

/// Single-select chip group -- the review screen's answer to "tappable
/// chips for AI-suggested enums, no free-form typing required for the
/// common case" (Phase 6 plan). Mirrors FormMultiSelect's API/style but
/// uses ChoiceChip (mutually-exclusive) instead of FilterChip.
class FormChipSelect<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final T? selected;
  final String Function(T) labelBuilder;
  final void Function(T?) onChanged;

  /// Values in [options] that came from the AI-suggestion pass -- rendered
  /// with a highlighted border so the person can see, at a glance, which
  /// chip is the suggestion versus a plain manual choice.
  final Set<T> suggested;

  const FormChipSelect({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
    this.suggested = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((o) {
              final isSelected = selected == o;
              final isSuggested = suggested.contains(o);

              return ChoiceChip(
                label: Text(labelBuilder(o)),
                selected: isSelected,
                onSelected: (v) => onChanged(v ? o : null),
                avatar: isSuggested && !isSelected
                    ? Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: theme.colorScheme.primary,
                      )
                    : null,
                side: isSuggested
                    ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
