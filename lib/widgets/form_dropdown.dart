import 'package:flutter/material.dart';

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