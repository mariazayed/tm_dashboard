import 'package:flutter/material.dart';

import '../../enums/goal_category_enum.dart';
import '../../enums/goal_status_enum.dart';
import '../../models/goal_model.dart';
import '../../services/goal_service.dart';
import 'add_goal_sheet.dart';
import 'goal_card.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late Future<List<GoalModel>> future;
  GoalCategoryEnum? categoryFilter;
  bool showHistory = false;

  @override
  void initState() {
    super.initState();
    future = GoalService.getAll();
  }

  void _refresh() {
    setState(() {
      future = GoalService.getAll();
    });
  }

  Future<void> _openAddGoal({GoalModel? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddGoalSheet(existing: existing),
    );
    _refresh();
  }

  Future<void> _confirmDelete(GoalModel goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete goal'),
        content: Text('Delete "${goal.title}"? This cannot be undone.'),
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
      await GoalService.delete(goal.id);
      _refresh();
    }
  }

  Future<void> _setStatus(GoalModel goal, GoalStatusEnum status) async {
    await GoalService.update(goal.id, goal.copyWith(status: status).toUpdateJson());
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _openAddGoal()),
        ],
      ),
      body: FutureBuilder<List<GoalModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load goals:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final goals = snapshot.data ?? [];

          final active = goals.where((g) => g.status == GoalStatusEnum.ACTIVE).toList();
          final history = goals.where((g) => g.status != GoalStatusEnum.ACTIVE).toList();

          final filteredActive = categoryFilter == null
              ? active
              : active.where((g) => g.category == categoryFilter).toList();

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildCategoryFilters(),
                const SizedBox(height: 20),
                if (filteredActive.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.flag_outlined, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            goals.isEmpty
                                ? 'No goals yet — set your first one'
                                : 'No active goals in this category',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildGrid(filteredActive),
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => setState(() => showHistory = !showHistory),
                    child: Row(
                      children: [
                        Icon(
                          showHistory ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'History (${history.length})',
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (showHistory) ...[
                    const SizedBox(height: 12),
                    _buildGrid(history),
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
        ...GoalCategoryEnum.values.map(
          (c) => ChoiceChip(
            label: Text(c.label),
            selected: categoryFilter == c,
            onSelected: (_) => setState(() => categoryFilter = c),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(List<GoalModel> goals) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 340).floor().clamp(1, 3).toInt();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: goals.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 190,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (_, i) => GoalCard(
            goal: goals[i],
            onEdit: () => _openAddGoal(existing: goals[i]),
            onDelete: () => _confirmDelete(goals[i]),
            onSetStatus: (status) => _setStatus(goals[i], status),
          ),
        );
      },
    );
  }
}
