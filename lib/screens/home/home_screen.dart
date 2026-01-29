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
    setState(() {
      _isLoading = true;
    });

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
        setState(() {
          _isLoading = false;
        });
        throw Exception('Failed to load notes');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error fetching notes: $e');
    }
  }

  Widget _buildStickyNote(String text) {
    final random = Random();
    final rotation = (random.nextDouble() * 0.1 - 0.05); // small rotation

    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.yellow.shade300,
          borderRadius: BorderRadius.circular(12),
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
            : _buildStickyNote(_notes[_currentIndex].text),
      ),
    );
  }
}
