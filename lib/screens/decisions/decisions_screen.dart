import 'package:flutter/material.dart';

import '../../enums/decision_category_enum.dart';
import '../../enums/decision_status_enum.dart';
import '../../models/decision_model.dart';
import '../../services/api_client.dart';
import '../../services/decision_service.dart';
import '../../theme/app_theme.dart';
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
  bool showResolved = true;

  @override
  void initState() {
    super.initState();
    // Paged transport under the hood (DecisionService.getAllPaged ->
    // .../decision/search) instead of one unbounded GET.
    future = DecisionService.getAllPaged();
  }

  Future<void> _refresh() async {
    setState(() {
      future = DecisionService.getAllPaged();
    });
    try {
      await future;
    } catch (_) {
      // The FutureBuilder displays the load error.
    }
  }

  Future<void> _openAddDecision(
    List<DecisionModel> allDecisions, {
    DecisionModel? existing,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddDecisionSheet(existing: existing, allDecisions: allDecisions),
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DecisionService.delete(decision.id);
      _refresh();
    }
  }

  Future<void> _setStatus(
    DecisionModel decision,
    DecisionStatusEnum status,
  ) async {
    await DecisionService.update(
      decision.id,
      decision.copyWith(status: status).toUpdateJson(),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      // No explicit backgroundColor override -- falls back to the theme's
      // scaffoldBackgroundColor/appBarTheme, same as every other screen
      // (Dashboard included), so this page's background matches the rest
      // of the app instead of standing out.
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: const Text('Decisions'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
              onPressed: () async {
                final current = await future;
                if (!mounted) return;
                _openAddDecision(current);
              },
            ),
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

          final decisions = <DecisionModel>[...snapshot.data ?? []]
            ..sort((a, b) => b.decisionDate.compareTo(a.decisionDate));

          final active = decisions
              .where((d) => d.status == DecisionStatusEnum.ACTIVE)
              .toList();
          final resolved = decisions
              .where((d) => d.status != DecisionStatusEnum.ACTIVE)
              .toList();

          final filteredActive = categoryFilter == null
              ? active
              : active.where((d) => d.category == categoryFilter).toList();

          final filteredResolved = categoryFilter == null
              ? resolved
              : resolved.where((d) => d.category == categoryFilter).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 700
                  ? 16.0
                  : 28.0;

              return RefreshIndicator(
                onRefresh: () => ApiClient.shared.refresh(_refresh),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    32,
                  ),
                  children: [
                    _buildSummary(decisions, active.length, resolved.length),
                    const SizedBox(height: 16),
                    _buildCategoryFilters(),
                    const SizedBox(height: 16),
                    if (filteredActive.isEmpty && filteredResolved.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 56),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.fact_check_outlined,
                                size: 48,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                decisions.isEmpty
                                    ? 'No decisions logged yet'
                                    : 'No decisions in this category',
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                          onEdit: () =>
                              _openAddDecision(decisions, existing: d),
                          onDelete: () => _confirmDelete(d),
                          onSetStatus: (status) => _setStatus(d, status),
                        ),
                      ),
                    if (filteredResolved.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildResolvedToggle(filteredResolved.length),
                      if (showResolved) ...[
                        const SizedBox(height: 12),
                        ...filteredResolved.map(
                          (d) => DecisionCard(
                            decision: d,
                            allDecisions: decisions,
                            onEdit: () =>
                                _openAddDecision(decisions, existing: d),
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
          );
        },
      ),
    );
  }

  Widget _buildSummary(
    List<DecisionModel> decisions,
    int activeCount,
    int resolvedCount,
  ) {
    final latest = decisions.isEmpty ? null : decisions.first;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _summaryMetric(
            'Active',
            activeCount.toString(),
            semantic.profit,
          ),
          _summaryMetric(
            'Resolved',
            resolvedCount.toString(),
            colorScheme.onSurfaceVariant,
          ),
          _summaryMetric(
            'Total',
            decisions.length.toString(),
            colorScheme.primary,
          ),
          if (latest != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Text(
                'Latest: #${latest.decisionNumber ?? '-'}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterButton(
            'All',
            categoryFilter == null,
            () => setState(() => categoryFilter = null),
          ),
          ...DecisionCategoryEnum.values.map(
            (c) => _filterButton(
              c.label,
              categoryFilter == c,
              () => setState(() => categoryFilter = c),
            ),
          ),
        ],
      ),
    );
  }

  /// Selected filter now uses the brand primary color (instead of the
  /// original design's near-black) so its selected/unselected contrast
  /// stays correct in dark mode too -- a deliberate judgment call, not an
  /// exact color port.
  Widget _filterButton(String label, bool selected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check, size: 14, color: colorScheme.onPrimary),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResolvedToggle(int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => showResolved = !showResolved),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              showResolved
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Resolved archive',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
