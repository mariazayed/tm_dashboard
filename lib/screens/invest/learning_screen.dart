import 'package:flutter/material.dart';
import 'package:tm_dashboard/widgets/page_back_button.dart';

import '../../services/learning_service.dart';
import 'flashcard_review_tab.dart';
import 'learning_notes_tab.dart';
import 'reading_list_tab.dart';

/// Reading list, learning notes and flashcard review in one place.
class LearningScreen extends StatelessWidget {
  const LearningScreen({super.key, LearningService? service})
    : _service = service;

  final LearningService? _service;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PageBackButton(),
                Text(
                  'Learning',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Reading list'),
                Tab(text: 'Notes'),
                Tab(text: 'Review'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ReadingListTab(service: _service),
                  LearningNotesTab(service: _service),
                  FlashcardReviewTab(service: _service),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
