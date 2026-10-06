import 'package:flutter/material.dart';

import '../../models/invest/contribution_model.dart';
import '../../models/invest/invest_settings_model.dart';
import '../../models/invest/money.dart';
import '../../models/invest/plan_model.dart';
import '../../services/contribution_service.dart';
import '../../services/plan_service.dart';
import 'invest_ui.dart';

/// The plan (amount, buy day, ticker...) and the reminder preferences.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    PlanService? plan,
    ContributionService? contributions,
  }) : _plan = plan,
       _contributions = contributions;

  final PlanService? _plan;
  final ContributionService? _contributions;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _amount = TextEditingController();
  final _currency = TextEditingController();
  final _ticker = TextEditingController();
  final _timezone = TextEditingController();
  final _email = TextEditingController();
  int _buyDay = 1;
  int _followup = 3;
  bool _reminders = false;
  late DateTime _startDate;
  ReminderStatusModel? _status;
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  String? _loadError;
  String? _error;
  String? _saved;
  String? _testMessage;

  PlanService get _plan => widget._plan ?? PlanService.shared;
  ContributionService get _contributions =>
      widget._contributions ?? ContributionService.shared;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_amount, _currency, _ticker, _timezone, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _contributions.getSettings(),
        _plan
            .reminderStatus()
            .then<ReminderStatusModel?>((s) => s)
            .catchError((_) => null),
      ]);
      final s = results[0] as InvestSettingsModel;
      if (!mounted) return;
      setState(() {
        _fill(s);
        _status = results[1] as ReminderStatusModel?;
        _loading = false;
      });
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) {
        setState(() {
          _loadError = message;
          _loading = false;
        });
      }
    }
  }

  void _fill(InvestSettingsModel s) {
    _amount.text = Money.plain(s.monthlyAmountCents);
    _currency.text = s.currency;
    _ticker.text = s.ticker;
    _timezone.text = s.timezone;
    _email.text = s.reminderEmail ?? '';
    _buyDay = s.buyDay;
    _followup = s.reminderFollowupDays;
    _reminders = s.remindersEnabled;
    _startDate = s.startDate;
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _startDate,
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  /// Builds the request, or sets [_error] and returns null.
  Map<String, dynamic>? _payload() {
    final cents = Money.parseCents(_amount.text);
    if (cents == null || cents <= 0) {
      setState(() => _error = 'Enter the monthly amount like 300 or 300.00');
      return null;
    }
    final currency = _currency.text.trim();
    if (!RegExp(r'^[A-Za-z]{3}$').hasMatch(currency)) {
      setState(() => _error = 'Currency is a 3-letter code such as USD');
      return null;
    }
    final ticker = _ticker.text.trim();
    if (!RegExp(r'^[A-Za-z0-9.\-]{1,16}$').hasMatch(ticker)) {
      setState(() => _error = 'Ticker can use letters, digits, "." and "-"');
      return null;
    }
    final email = _email.text.trim();
    if (_reminders && email.isEmpty) {
      setState(() => _error = 'Add an email address to turn reminders on');
      return null;
    }
    return {
      'monthlyAmountCents': cents,
      'currency': currency,
      'buyDay': _buyDay,
      'ticker': ticker,
      'startDate': ContributionModel.dateString(_startDate),
      'timezone': _timezone.text.trim(),
      'remindersEnabled': _reminders,
      'reminderEmail': email.isEmpty ? null : email,
      'reminderFollowupDays': _followup,
    };
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _saved = null;
    });
    final payload = _payload();
    if (payload == null) return;
    setState(() => _saving = true);
    try {
      final saved = await _plan.updateSettings(payload);
      if (!mounted) return;
      setState(() {
        _fill(saved);
        _saved = 'Saved';
      });
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendTest() async {
    setState(() {
      _testing = true;
      _testMessage = null;
    });
    try {
      final result = await _plan.sendTestReminder();
      if (mounted) setState(() => _testMessage = result.message);
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) setState(() => _testMessage = message);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) return Center(child: Text(_loadError!));
    final status = _status;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Plan settings', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            TextField(
              key: const Key('amount-field'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Monthly amount'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('currency-field'),
                    controller: _currency,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 3,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const Key('ticker-field'),
                    controller: _ticker,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'ETF ticker'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: const Key('buy-day'),
              initialValue: _buyDay,
              decoration: const InputDecoration(
                labelText: 'Buy day of the month',
                helperText: 'Up to the 28th, so every month has it',
              ),
              items: [
                for (var d = 1; d <= 28; d++)
                  DropdownMenuItem(value: d, child: Text('$d')),
              ],
              onChanged: (v) => setState(() => _buyDay = v ?? _buyDay),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('start-date'),
              onPressed: _pickStart,
              child: Text(
                'Plan started ${ContributionModel.dateString(_startDate)}',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('timezone-field'),
              controller: _timezone,
              decoration: const InputDecoration(
                labelText: 'Timezone',
                helperText: 'For example Europe/Berlin or America/New_York',
              ),
            ),
            const Divider(height: 40),
            Text('Reminders', style: theme.textTheme.titleMedium),
            SwitchListTile(
              key: const Key('reminders-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Email me on buy day'),
              subtitle: const Text(
                'One email if nothing is bought yet, one nudge a few days later. '
                'Nothing once you have logged the month.',
              ),
              value: _reminders,
              onChanged: (v) => setState(() => _reminders = v),
            ),
            if (status != null && !status.emailConfigured)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'The server has no email settings yet, so reminders cannot be '
                  'delivered. See docs/INVESTMENT_TRACKER.md on the server.',
                  key: const Key('email-not-configured'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            TextField(
              key: const Key('email-field'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Reminder email'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: const Key('followup-days'),
              initialValue: _followup,
              decoration: const InputDecoration(labelText: 'Nudge again after'),
              items: [
                for (var d = 1; d <= 14; d++)
                  DropdownMenuItem(
                    value: d,
                    child: Text('$d ${d == 1 ? 'day' : 'days'}'),
                  ),
              ],
              onChanged: (v) => setState(() => _followup = v ?? _followup),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('send-test'),
                onPressed: _testing ? null : _sendTest,
                child: Text(_testing ? 'Sending…' : 'Send a test email'),
              ),
            ),
            if (_testMessage != null)
              Text(_testMessage!, key: const Key('test-message')),
            if (status != null && status.recent.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Recently sent', style: theme.textTheme.bodySmall),
              for (final r in status.recent)
                Text(
                  '${r.month}: ${r.label}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  key: const Key('form-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (_saved != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(_saved!, key: const Key('saved-note')),
              ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('save-settings'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save settings'),
            ),
          ],
        ),
      ),
    );
  }
}
