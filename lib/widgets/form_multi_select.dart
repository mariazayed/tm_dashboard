import 'package:flutter/material.dart';

class FormMultiSelect<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final List<T> selected;
  final String Function(T) labelBuilder;
  final void Function(List<T>) onChanged;

  const FormMultiSelect({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((o) {
              final isSelected = selected.contains(o);

              return FilterChip(
                label: Text(labelBuilder(o)),
                selected: isSelected,
                showCheckmark: true,
                onSelected: (v) {
                  final updated = List<T>.from(selected);
                  v ? updated.add(o) : updated.remove(o);
                  onChanged(updated);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
