import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tm_dashboard/models/reminder_note_model.dart';
import 'package:tm_dashboard/services/reminder_notes_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ReminderNoteModel> _notes = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Timer? _timer;

  // Modern light colors for sticky notes
  final List<Color> _noteColors = [
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotes() async {
    setState(() => _isLoading = true);

    try {
      final response = await ReminderNotesService.getAll();
      if (response.isNotEmpty) {
        final notes = response;

        setState(() {
          _notes = notes;
          _isLoading = false;
        });

        if (_notes.isNotEmpty) {
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
            setState(() {
              _currentIndex = (_currentIndex + 1) % _notes.length;
            });
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching notes: $e');
    }
  }

  Widget _buildStickyNote({required Widget child, required Color color}) {
    return Container(
      width: 300,
      height: 300,
      // square sticky note
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color, // dynamic background color
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(3, 3)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _NotebookLinesOnlyPainter()),
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color currentColor = _noteColors[_currentIndex % _noteColors.length];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Center(
        child: _isLoading
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
                  color: currentColor, // dynamic background color
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
                      child: CustomPaint(painter: _NotebookLinesOnlyPainter()),
                    ),
                    Text(
                      _notes[_currentIndex].text,
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
      ),
    );
  }
}

// Notebook lines painter (no spirals)
class _NotebookLinesOnlyPainter extends CustomPainter {
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
