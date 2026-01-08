import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon,
                        size: 20, color: Theme.of(context).colorScheme.primary),
                  ),
                if (icon != null) const SizedBox(width: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class FormDropdown<T> extends StatelessWidget {
  final String label;
  final List<T> items;
  final T? value;
  final String Function(T) labelBuilder;
  final ValueChanged<T?> onChanged;

  const FormDropdown({
    super.key,
    required this.label,
    required this.items,
    this.value,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map(
              (e) =>
                  DropdownMenuItem<T>(value: e, child: Text(labelBuilder(e))),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class FormNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final Color? fillColor;

  const FormNumberField({
    super.key,
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          filled: fillColor != null,
          fillColor: fillColor,
        ),
      ),
    );
  }
}

class FormTextAreaField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const FormTextAreaField({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        minLines: 1,
        maxLines: 5,
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

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
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                        : Colors.grey.shade200,
                  ),
                ),
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFF374151),
                ),
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
