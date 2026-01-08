import 'package:flutter/material.dart';

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