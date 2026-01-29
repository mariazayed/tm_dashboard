import 'package:flutter/material.dart';
import 'package:tm_dashboard/models/reminder_note_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:tm_dashboard/services/reminder_notes_service.dart';

class ReminderNotesScreen extends StatefulWidget {
  const ReminderNotesScreen({super.key});

  @override
  State<ReminderNotesScreen> createState() => _ReminderNotesScreenState();
}

class _ReminderNotesScreenState extends State<ReminderNotesScreen> {
  List<ReminderNoteModel> _notes = [];
  bool _isLoading = true;
  bool _isAdding = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _isLoading = true;
    });
    try {
        setState(() async {
          _notes = await ReminderNotesService.getAll();
          _isLoading = false;
        });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error fetching notes: $e');
    }
  }

  Future<void> _addNote(String text) async {
    try {
      ReminderNoteModel noteModel = ReminderNoteModel(text: text);
      await ReminderNotesService.create([noteModel.toJson()]);
        _controller.clear();
        _fetchNotes();
        setState(() {
          _isAdding = false;
        });
    } catch (e) {
      debugPrint('Error adding note: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Notes'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchNotes,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            final note = _notes[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  note.text,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isAdding = !_isAdding;
          });
        },
        child: Icon(_isAdding ? Icons.close : Icons.add),
      ),
      bottomSheet: _isAdding
          ? Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Enter new note...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                final text = _controller.text.trim();
                if (text.isNotEmpty) {
                  _addNote(text);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              child: const Text('Add'),
            )
          ],
        ),
      )
          : null,
    );
  }
}
