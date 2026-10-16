import 'package:flutter/material.dart';
import 'package:tm_dashboard/widgets/page_back_button.dart';

import '../../models/invest/plan_model.dart';
import '../../services/plan_service.dart';
import 'consistency_card.dart';
import 'invest_ui.dart';

/// Add, edit, delete and drag-to-reorder the rules.
class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key, PlanService? service}) : _service = service;

  final PlanService? _service;

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  final _newRule = TextEditingController();
  List<RuleModel> _rules = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  PlanService get _service => widget._service ?? PlanService.shared;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newRule.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final rules = await _service.rules();
      if (mounted) {
        setState(() {
          _rules = rules;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) {
        setState(() {
          _error = message;
          _loading = false;
        });
      }
    }
  }

  /// Runs [action] with the screen locked, then reloads from the server.
  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (e) {
      final message = await describeInvestError(e);
      if (mounted) showToast(context, message);
      await _load(); // fall back to what the server really has
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final text = _newRule.text.trim();
    if (text.isEmpty) return;
    await _mutate(() async {
      await _service.createRule(text);
      _newRule.clear();
    });
  }

  Future<void> _edit(RuleModel rule) async {
    final text = await askForText(
      context,
      title: 'Edit rule',
      initialText: rule.text,
      maxLength: 500,
      fieldKey: const Key('edit-rule-field'),
    );
    if (text == null || text.isEmpty || text == rule.text) return;
    await _mutate(() => _service.updateRule(rule.id, text));
  }

  Future<void> _delete(RuleModel rule) async {
    final ok = await confirmDelete(
      context,
      title: 'Delete rule?',
      message: '"${rule.text}" will be removed from your rules.',
    );
    if (ok) await _mutate(() => _service.deleteRule(rule.id));
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex == oldIndex) return;
    final reordered = [..._rules];
    reordered.insert(newIndex, reordered.removeAt(oldIndex));
    setState(() => _rules = reordered); // show the move immediately
    await _mutate(() async {
      await _service.reorderRules(reordered.map((r) => r.id).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PageBackButton(),
              Text('Your Rules', style: theme.textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Written while you are calm, read when you are not. Drag to reorder.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('new-rule-field'),
                  controller: _newRule,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Add a rule',
                    counterText: '',
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('add-rule'),
                onPressed: _busy ? null : _add,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _rules.isEmpty
                ? const Center(
                    key: Key('no-rules'),
                    child: Text('No rules yet. Add your first one above.'),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: true,
                    itemCount: _rules.length,
                    // onReorderItem only exists in newer Flutter; onReorder works on both.
                    // ignore: deprecated_member_use
                    onReorder: _reorder,
                    itemBuilder: (context, i) {
                      final rule = _rules[i];
                      return Card(
                        key: ValueKey('rule-${rule.id}'),
                        child: ListTile(
                          leading: Text('${i + 1}.'),
                          title: Text(rule.text),
                          onTap: () => _edit(rule),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: _busy ? null : () => _delete(rule),
                              ),
                              const SizedBox(
                                width: 28,
                              ), // room for the drag handle
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          ConsistencyCard(service: _service),
        ],
      ),
    );
  }
}
