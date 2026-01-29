import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tm_dashboard/models/reminder_note_model.dart';
import 'package:tm_dashboard/services/reminder_notes_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ReminderNoteModel> _notes = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  Timer? _timer;

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
          // Start rotating sticky notes every 5 seconds
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
            setState(() {
              _currentIndex = (_currentIndex + 1) % _notes.length;
            });
          });
        }
      } else {
        setState(() => _isLoading = false);
        throw Exception('Failed to load notes');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching notes: $e');
    }
  }

  Widget _buildStickyNote(String text, {Key? key}) {
    final random = Random();
    final rotation = (random.nextDouble() * 0.1 - 0.05); // small rotation

    return Transform.rotate(
      key: key, // assign the key here
      angle: rotation,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.yellow.shade300,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(3, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }


  void _showAllNotes() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              final note = _notes[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade200,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
                child: Text(
                  note.text,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Sticky Notes'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _notes.isEmpty
            ? const Text('No notes available')
            : GestureDetector(
          onTap: _showAllNotes,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                    begin: const Offset(1, 0), end: Offset.zero)
                    .animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _buildStickyNote(
              _notes[_currentIndex].text,
              // Give each child a unique key to animate properly
              key: ValueKey<int>(_currentIndex),
            ),
          ),
        ),
      ),
    );
  }
}
