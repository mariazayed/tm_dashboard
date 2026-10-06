import 'package:flutter/material.dart';

import '../../services/contribution_service.dart';
import '../auth/auth_cubit.dart';

/// Turns any failure into text for the user. An expired login also signs the
/// user out, which sends the router back to the login screen.
Future<String> describeInvestError(Object e) async {
  if (e is InvestApiException) {
    if (e.unauthorized) await authCubit.logout();
    return e.message;
  }
  return 'Could not reach the server';
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Asks for a line or two of text. The dialog owns its controller, so it is
/// disposed only after the closing animation has finished (disposing a
/// controller right after `showDialog` returns crashes the exiting dialog).
///
/// Returns the trimmed text, or null if cancelled.
Future<String?> askForText(
  BuildContext context, {
  required String title,
  String initialText = '',
  String? hint,
  String confirmLabel = 'Save',
  int minLines = 1,
  int maxLines = 4,
  int? maxLength,
  double? width,
  Key? fieldKey,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextEntryDialog(
      title: title,
      initialText: initialText,
      hint: hint,
      confirmLabel: confirmLabel,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      width: width,
      fieldKey: fieldKey,
    ),
  );
}

class _TextEntryDialog extends StatefulWidget {
  const _TextEntryDialog({
    required this.title,
    required this.initialText,
    required this.confirmLabel,
    required this.minLines,
    required this.maxLines,
    this.hint,
    this.maxLength,
    this.width,
    this.fieldKey,
  });

  final String title;
  final String initialText;
  final String? hint;
  final String confirmLabel;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final double? width;
  final Key? fieldKey;

  @override
  State<_TextEntryDialog> createState() => _TextEntryDialogState();
}

class _TextEntryDialogState extends State<_TextEntryDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: widget.width,
        child: TextField(
          key: widget.fieldKey,
          controller: _controller,
          autofocus: true,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          decoration: InputDecoration(hintText: widget.hint),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
