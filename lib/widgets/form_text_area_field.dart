import 'package:flutter/material.dart';

class FormTextAreaField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;

  const FormTextAreaField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
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
        decoration: InputDecoration(labelText: label, hintText: hintText),
      ),
    );
  }
}
