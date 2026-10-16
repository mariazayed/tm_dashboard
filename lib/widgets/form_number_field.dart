import 'package:flutter/material.dart';

class FormNumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final Color? fillColor;
  final String? hintText;
  final String? helperText;

  const FormNumberField({
    super.key,
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.fillColor,
    this.hintText,
    this.helperText,
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
          hintText: hintText,
          helperText: helperText,
          filled: fillColor != null,
          fillColor: fillColor,
        ),
      ),
    );
  }
}
