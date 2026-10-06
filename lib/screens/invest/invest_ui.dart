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
