import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tm_dashboard/models/reminder_note_model.dart';
import 'package:tm_dashboard/models/strict_rule_model.dart';
import 'package:tm_dashboard/services/reminder_notes_service.dart';
import 'package:tm_dashboard/services/strict_rules_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
      body: Center(
        child: Row(
          children: [
            _isNotesLoading
                ? const CircularProgressIndicator()
                : _notes.isEmpty
                ? const Text('No notes available')
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    // smooth fade
                    curve: Curves.easeInOut,
                    width: 300,
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: currentNoteColor, // dynamic background color
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: _NotebookLinesPainter()),
                        ),
                        Text(
                          _notes[_currentNoteIndex].text,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: Colors.grey.shade900,
                            shadows: const [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

            _isRulesLoading
                ? const CircularProgressIndicator()
                : _rules.isEmpty
                ? const Text('No rules available')
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    // smooth fade
                    curve: Curves.easeInOut,
                    width: 300,
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: currentRuleColor, // dynamic background color
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: _NotebookLinesPainter()),
                        ),
                        Text(
                          _rules[_currentRuleIndex].text,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: Colors.grey.shade900,
                            shadows: const [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _NotebookLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    const double lineSpacing = 24;
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
