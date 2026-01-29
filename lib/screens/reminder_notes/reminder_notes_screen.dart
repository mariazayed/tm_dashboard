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
  List<String> _draftNotes = [];
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

  void _addDraftNote() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _draftNotes.add(text);
        _controller.clear();
      });
    }
  }

  Future<void> _submitAllDrafts() async {
    if (_draftNotes.isEmpty) return;

    try {

      List<dynamic> notes = _draftNotes.map((text) => ReminderNoteModel(text: text).toJson()
      ).toList();

      await ReminderNotesService.create([...notes]);

        setState(() {
          _draftNotes.clear();
          _isAdding = false;
        });
        _fetchNotes();
    } catch (e) {
      debugPrint('Error submitting notes: $e');
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._notes.map((note) => Card(
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
            )),
            if (_draftNotes.isNotEmpty)
              const SizedBox(height: 16),
            ..._draftNotes.map((draft) => Card(
              color: Colors.blue.shade50,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  draft,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            )),
          ],
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                  onPressed: _addDraftNote,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            if (_draftNotes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  onPressed: _submitAllDrafts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Center(
                    child: Text(
                      'Submit All',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      )
          : null,
    );
  }
}
