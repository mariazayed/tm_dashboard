import 'package:flutter/material.dart';

import '../../enums/decision_category_enum.dart';
import '../../enums/decision_status_enum.dart';
import '../../models/decision_model.dart';
import '../../services/decision_service.dart';
import 'add_decision_sheet.dart';
import 'decision_card.dart';

class DecisionsScreen extends StatefulWidget {
  const DecisionsScreen({super.key});

  @override
  State<DecisionsScreen> createState() => _DecisionsScreenState();
}

class _DecisionsScreenState extends State<DecisionsScreen> {
  late Future<List<DecisionModel>> future;
  DecisionCategoryEnum? categoryFilter;
  bool showResolved = false;

  @override
  void initState() {
    super.initState();
    // Paged transport under the hood (DecisionService.getAllPaged ->
    // .../decision/search) instead of one unbounded GET.
    future = DecisionService.getAllPaged();
  }

  void _refresh() {
    setState(() {
      future = DecisionService.getAllPaged();
    });
  }

  Future<void> _openAddDecision(List<DecisionModel> allDecisions, {DecisionModel? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddDecisionSheet(existing: existing, allDecisions: allDecisions),
    );
    _refresh();
  }

  Future<void> _confirmDelete(DecisionModel decision) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete decision'),
        content: Text('Delete "${decision.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      await DecisionService.delete(decision.id);
      _refresh();
    }
  }

  Future<void> _setStatus(DecisionModel decision, DecisionStatusEnum status) async {
    await DecisionService.update(decision.id, decision.copyWith(status: status).toUpdateJson());
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decisions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final current = await future;
              if (!mounted) return;
              _openAddDecision(current);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<DecisionModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load decisions:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final decisions = [...snapshot.data ?? []]
            ..sort((a, b) => b.decisionDate.compareTo(a.decisionDate));

          final active = decisions.where((d) => d.status == DecisionStatusEnum.ACTIVE).toList();
          final resolved = decisions.where((d) => d.status != DecisionStatusEnum.ACTIVE).toList();

          final filteredActive = categoryFilter == null
              ? active
              : active.where((d) => d.category == categoryFilter).toList();

          final filteredResolved = categoryFilter == null
              ? resolved
              : resolved.where((d) => d.category == categoryFilter).toList();

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildCategoryFilters(),
                const SizedBox(height: 20),
                if (filteredActive.isEmpty && filteredResolved.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.fact_check_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            decisions.isEmpty ? 'No decisions logged yet' : 'No decisions in this category',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredActive.map(
                    (d) => DecisionCard(
                      decision: d,
                      allDecisions: decisions,
                      onEdit: () => _openAddDecision(decisions, existing: d),
                      onDelete: () => _confirmDelete(d),
                      onSetStatus: (status) => _setStatus(d, status),
                    ),
                  ),
                if (filteredResolved.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => setState(() => showResolved = !showResolved),
                    child: Row(
                      children: [
                        Icon(
                          showResolved ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Superseded / Reversed / Completed (${filteredResolved.length})',
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (showResolved) ...[
                    const SizedBox(height: 12),
                    ...filteredResolved.map(
                      (d) => DecisionCard(
                        decision: d,
                        allDecisions: decisions,
                        onEdit: () => _openAddDecision(decisions, existing: d),
                        onDelete: () => _confirmDelete(d),
                        onSetStatus: (status) => _setStatus(d, status),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: categoryFilter == null,
          onSelected: (_) => setState(() => categoryFilter = null),
        ),
        ...DecisionCategoryEnum.values.map(
          (c) => ChoiceChip(
            label: Text(c.label),
            selected: categoryFilter == c,
            onSelected: (_) => setState(() => categoryFilter = c),
          ),
        ),
      ],
    );
  }
}
