import 'dart:convert';

import 'package:flutter/material.dart';

import '../../constants/api_constants.dart';
import '../../services/api_client.dart';
import '../auth/auth_cubit.dart';

/// Landing page of the investing tracker. Contributions, journal and
/// learning notes will hang off this route in later phases.
class InvestHomeScreen extends StatefulWidget {
  const InvestHomeScreen({super.key});

  @override
  State<InvestHomeScreen> createState() => _InvestHomeScreenState();
}

class _InvestHomeScreenState extends State<InvestHomeScreen> {
  late Future<bool> _serverOk;

  @override
  void initState() {
    super.initState();
    _serverOk = _ping();
  }

  Future<bool> _ping() async {
    final response = await ApiClient.shared.get(
      Uri.parse('${ApiConstants.investURL}/ping'),
    );
    if (response.statusCode == 401) {
      // Token expired or revoked: drop to the login screen.
      await authCubit.logout();
      return false;
    }
    return response.statusCode == 200 &&
        (jsonDecode(response.body) as Map)['status'] == 'ok';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invest', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            r'Plan: $300 / month into VT. Contributions, journal and learning '
            'notes are coming next.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FutureBuilder<bool>(
            future: _serverOk,
            builder: (context, snapshot) {
              final text = snapshot.connectionState != ConnectionState.done
                  ? 'Checking server…'
                  : (snapshot.data == true
                        ? 'Server connected'
                        : 'Server unreachable');
              return Text(text, style: theme.textTheme.bodySmall);
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: authCubit.logout,
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
