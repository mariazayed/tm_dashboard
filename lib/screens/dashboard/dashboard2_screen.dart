import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tm_dashboard/models/reminder_note_model.dart';
import 'package:tm_dashboard/models/strict_rule_model.dart';
import 'package:tm_dashboard/services/reminder_notes_service.dart';
import 'package:tm_dashboard/services/strict_rules_service.dart';

import 'notebook_lines_painter.dart';

class DashboardScreen2 extends StatefulWidget {
  const DashboardScreen2({super.key});

  @override
  State<DashboardScreen2> createState() => _DashboardScreen2State();
}

class _DashboardScreen2State extends State<DashboardScreen2> {
  List<ReminderNoteModel> _notes = [];
  List<StrictRuleModel> _rules = [];
  bool _isNotesLoading = true;
  bool _isRulesLoading = true;
  int _currentNoteIndex = 0;
  int _currentRuleIndex = 0;
  Timer? _notesTimer;
  Timer? _rulesTimer;

  // Modern light colors for sticky notes
  final List<Color> _colors = [
    Colors.yellow.shade100,
    Colors.blue.shade50,
    Colors.green.shade50,
    Colors.pink.shade50,
    Colors.orange.shade50,
    Colors.purple.shade50,
  ];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
    _fetchRules();
  }

  @override
  void dispose() {
    _notesTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isNotesLoading = true);

    try {
      final response = await ReminderNotesService.getAll();
      if (response.isNotEmpty) {
        final notes = List.of(response)..shuffle(Random());

        setState(() {
          _notes = notes;
          _currentNoteIndex = 0;
          _isNotesLoading = false;
        });

        if (_notes.isNotEmpty) {
          _notesTimer?.cancel();
          _notesTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
            setState(() {
              _currentNoteIndex = (_currentNoteIndex + 1) % _notes.length;
            });
          });
        }
      } else {
        setState(() => _isNotesLoading = false);
      }
    } catch (e) {
      setState(() => _isNotesLoading = false);
      debugPrint('Error fetching notes: $e');
    }
  }

  Future<void> _fetchRules() async {
    setState(() => _isRulesLoading = true);

    try {
      final response = await StrictRulesService.getAll();
      if (response.isNotEmpty) {
        final rules = List.of(response)..shuffle(Random());

        setState(() {
          _rules = rules;
          _currentRuleIndex = 0;
          _isRulesLoading = false;
        });

        if (_rules.isNotEmpty) {
          _rulesTimer?.cancel();
          _rulesTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
            setState(() {
              _currentRuleIndex = (_currentRuleIndex + 1) % _rules.length;
            });
          });
        }
      } else {
        setState(() => _isRulesLoading = false);
      }
    } catch (e) {
      setState(() => _isRulesLoading = false);
      debugPrint('Error fetching rules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color currentNoteColor = _colors[_currentNoteIndex % _colors.length];
    final Color currentRuleColor = _colors[_currentRuleIndex % _colors.length];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            return isWide
                ? Row(
                    children: [
                      Expanded(
                        child: _buildSection(
                          title: "Reminder",
                          loading: _isNotesLoading,
                          isEmpty: _notes.isEmpty,
                          text: _notes.isNotEmpty
                              ? _notes[_currentNoteIndex].text
                              : "",
                          color: currentNoteColor,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildSection(
                          title: "Strict Rule",
                          loading: _isRulesLoading,
                          isEmpty: _rules.isEmpty,
                          text: _rules.isNotEmpty
                              ? _rules[_currentRuleIndex].text
                              : "",
                          color: currentRuleColor,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildSection(
                        title: "Reminder",
                        loading: _isNotesLoading,
                        isEmpty: _notes.isEmpty,
                        text: _notes.isNotEmpty
                            ? _notes[_currentNoteIndex].text
                            : "",
                        color: currentNoteColor,
                      ),
                      const SizedBox(height: 24),
                      _buildSection(
                        title: "Strict Rule",
                        loading: _isRulesLoading,
                        isEmpty: _rules.isEmpty,
                        text: _rules.isNotEmpty
                            ? _rules[_currentRuleIndex].text
                            : "",
                        color: currentRuleColor,
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool loading,
    required bool isEmpty,
    required String text,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Section Title
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),

        loading
            ? const Center(child: CircularProgressIndicator())
            : isEmpty
            ? const Text("No data available")
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey(text),
                  padding: const EdgeInsets.all(24),
                  height: 280,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 30,
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: NotebookLinesPainter()),
                      ),
                      Center(
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }
}
