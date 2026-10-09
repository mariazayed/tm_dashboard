import 'package:flutter/material.dart';

import '../../models/invest/rule_check_model.dart';
import '../../services/plan_service.dart';
import 'invest_ui.dart';

/// "Recent consistency": what the last 30 days of your journal and plan look
/// like against your own rules. Computed by plain code on the server, so it
/// works with AI off. Findings are prompts to look, never verdicts.
class ConsistencyCard extends StatefulWidget {
  const ConsistencyCard({
    super.key,
    required this.service,
    this.now,
    this.days = 30,
  });

  final PlanService service;

  /// For tests; defaults to the current time.
  final DateTime Function()? now;
  final int days;

  @override
  State<ConsistencyCard> createState() => _ConsistencyCardState();
}

class _ConsistencyCardState extends State<ConsistencyCard> {
  RuleCheckModel? _result;
  String? _error;
  bool _loading = true;
  // A slow answer for an older refresh must not overwrite a newer one.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    final today = (widget.now ?? DateTime.now)();
    try {
      final result = await widget.service.ruleCheck(
        from: today.subtract(Duration(days: widget.days - 1)),
        to: today,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      final message = await describeInvestError(e);
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('consistency-card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent consistency',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const Key('consistency-refresh'),
                  tooltip: 'Check again',
                  icon: const Icon(Icons.refresh),
                  onPressed: _loading ? null : _load,
                ),
              ],
            ),
            Text(
              'The last ${widget.days} days, checked against your own rules. '
              'These are prompts to look, not verdicts.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            _content(theme),
          ],
        ),
      ),
    );
  }

  Widget _content(ThemeData theme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          key: Key('consistency-loading'),
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return Text(
        _error!,
        key: const Key('consistency-error'),
        style: TextStyle(color: theme.colorScheme.error),
      );
    }
    final result = _result!;
    final off = result.checks.where((c) => c.isOff).toList();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.findings.isEmpty)
              const Text(
                'Nothing to flag. What you did lined up with your rules.',
                key: Key('consistency-clear'),
              ),
            for (var i = 0; i < result.findings.length; i++)
              Padding(
                key: Key('finding-$i'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 8),
                      child: Icon(Icons.info_outline, size: 18),
                    ),
                    Expanded(
                      child: Text(
                        '${result.findings[i].date}: ${result.findings[i].message}',
                      ),
                    ),
                  ],
                ),
              ),
            for (final c in off)
              Padding(
                key: Key('check-off-${c.code}'),
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${c.label}: ${c.note ?? 'off'}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Tag a journal entry decision when you decide to deviate and '
              'deviation when you act. The wait is set in Settings.',
              key: const Key('consistency-help'),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
