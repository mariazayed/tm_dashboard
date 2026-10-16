import 'package:flutter/material.dart';

import 'package:tm_dashboard/widgets/page_back_button.dart';

import '../../models/question_category_model.dart';
import '../../models/question_answer_model.dart';
import '../../services/api_client.dart';
import '../../services/question_category_service.dart';
import '../../services/question_answer_service.dart';
import 'add_question_answer_sheet.dart';
import 'manage_question_categories_sheet.dart';
import 'question_answer_card.dart';

class _QuestionsAnswersData {
  final List<QuestionAnswerModel> questions;
  final List<QuestionCategoryModel> categories;

  const _QuestionsAnswersData({
    required this.questions,
    required this.categories,
  });
}

class QuestionsAnswersScreen extends StatefulWidget {
  const QuestionsAnswersScreen({super.key});

  @override
  State<QuestionsAnswersScreen> createState() => _QuestionsAnswersScreenState();
}

class _QuestionsAnswersScreenState extends State<QuestionsAnswersScreen> {
  late Future<_QuestionsAnswersData> future;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    future = _loadData();
  }

  Future<_QuestionsAnswersData> _loadData() async {
    final results = await Future.wait([
      QuestionAnswerService.getAllPaged(),
      QuestionCategoryService.getAllPaged(),
    ]);

    return _QuestionsAnswersData(
      questions: results[0] as List<QuestionAnswerModel>,
      categories: results[1] as List<QuestionCategoryModel>,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      future = _loadData();
    });
    try {
      await future;
    } catch (_) {
      // The FutureBuilder displays the load error.
    }
  }

  Future<void> _openEditor(
    List<QuestionCategoryModel> categories, {
    QuestionAnswerModel? existing,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddQuestionAnswerSheet(existing: existing, categories: categories),
    );
    _refresh();
  }

  Future<void> _openCategories() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ManageQuestionCategoriesSheet(),
    );
    _refresh();
  }

  Future<void> _confirmDelete(QuestionAnswerModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete question'),
        content: Text('Delete "${item.question}"? This cannot be undone.'),
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
      await QuestionAnswerService.delete(item.id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const PageBackButton(),
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        title: const Text('Questions & Answers'),
        actions: [
          IconButton(
            tooltip: 'New question',
            icon: const Icon(Icons.add),
            onPressed: () async {
              final data = await future;
              if (!mounted) return;
              if (data.categories.isEmpty) {
                await _openCategories();
              } else {
                _openEditor(data.categories);
              }
            },
          ),
          IconButton(
            tooltip: 'Manage categories',
            icon: const Icon(Icons.category_outlined),
            onPressed: _openCategories,
          ),
        ],
      ),
      body: FutureBuilder<_QuestionsAnswersData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load questions and answers:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final data =
              snapshot.data ??
              const _QuestionsAnswersData(questions: [], categories: []);
          final items = data.questions;
          final categories = data.categories;
          final filteredItems = _selectedCategoryId == null
              ? items
              : items
                    .where((item) => item.category?.id == _selectedCategoryId)
                    .toList();

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
                    _buildSummary(items.length, categories.length),
                    const SizedBox(height: 16),
                    _buildCategoryFilters(categories),
                    const SizedBox(height: 16),
                    if (filteredItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 56),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                size: 48,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                items.isEmpty
                                    ? 'No questions saved yet'
                                    : 'No questions in this category',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filteredItems.map(
                        (item) => QuestionAnswerCard(
                          item: item,
                          onEdit: () => _openEditor(categories, existing: item),
                          onDelete: () => _confirmDelete(item),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummary(int total, int categoryCount) {
    final colorScheme = Theme.of(context).colorScheme;

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
        children: [
          _summaryMetric('Saved', total.toString(), colorScheme.primary),
          _summaryMetric(
            'Categories',
            categoryCount.toString(),
            colorScheme.secondary,
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

  Widget _buildCategoryFilters(List<QuestionCategoryModel> categories) {
    final chips = [
      _categoryFilterChip('All', _selectedCategoryId == null, () {
        setState(() => _selectedCategoryId = null);
      }),
      ...categories.map(
        (category) => _categoryFilterChip(
          category.name,
          _selectedCategoryId == category.id,
          () => setState(() => _selectedCategoryId = category.id),
        ),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }

  Widget _categoryFilterChip(String label, bool selected, VoidCallback onTap) {
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
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
