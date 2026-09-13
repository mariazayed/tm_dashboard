import 'package:flutter/material.dart';
import 'package:tm_dashboard/models/reminder_note_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/reminder_notes_service.dart';

class ReminderNotesScreen extends StatefulWidget {
  const ReminderNotesScreen({Key? key}) : super(key: key);

  @override
  State<ReminderNotesScreen> createState() => _ReminderNotesScreenState();
}

class _ReminderNotesScreenState extends State<ReminderNotesScreen>
    with SingleTickerProviderStateMixin {
  List<ReminderNoteModel> _notes = [];
  final List<String> _draftNotes = [];
  bool _isLoading = true;
  bool _isAdding = false;
  // True while _submitAllDrafts()'s create request is in flight.
  bool _isSubmittingDrafts = false;
  // Ids with a delete request currently in flight, so only that note's
  // delete button shows a spinner instead of the whole screen blocking.
  final Set<int> _deletingNoteIds = {};

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    // Step 1: update loading state synchronously
    setState(() {
      _isLoading = true;
    });

    try {
      // Step 2: perform async work outside of setState. Paged transport
      // under the hood (ReminderNotesService.getAllPaged ->
      // .../reminder-note/search) instead of one unbounded GET.
      final response =  await ReminderNotesService.getAllPaged();

      if (response.isNotEmpty) {
        final notes = response;

        // Step 3: update state synchronously after async work
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      } else {
        // handle error
        setState(() {
          _notes = [];
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
    if (_draftNotes.isEmpty || _isSubmittingDrafts) return;
    setState(() => _isSubmittingDrafts = true);
    try {
      List<dynamic> notes = _draftNotes.map((text) => ReminderNoteModel(text: text, id: 0).toJson()
      ).toList();

      await ReminderNotesService.create([...notes]);

      setState(() {
        _draftNotes.clear();
        _isAdding = false;
        _isSubmittingDrafts = false;
      });
      _fetchNotes();
    } catch (e) {
      debugPrint('Error submitting notes: $e');
      if (mounted) setState(() => _isSubmittingDrafts = false);
    }
  }

  Widget _buildNoteCard(
      String text, {
        bool isDraft = false,
        bool isDeleting = false,
        VoidCallback? onDelete,
      }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDraft ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isDraft ? Colors.black87 : Colors.black,
                ),
              ),
            ),
            if (!isDraft && isDeleting)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (!isDraft && onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNote(int id) async {
    if (_deletingNoteIds.contains(id)) return;
    setState(() => _deletingNoteIds.add(id));
    try {
      await ReminderNotesService.delete(id);

      // Option A: refetch from API (safest)
      await _fetchNotes();

      // Option B (optional): optimistic update
      // setState(() {
      //   _notes.removeWhere((note) => note.id == id);
      // });
    } catch (e) {
      debugPrint('Error deleting note: $e');
    } finally {
      if (mounted) setState(() => _deletingNoteIds.remove(id));
    }
  }

  Future<void> _confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteNote(id);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Reminder Notes'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchNotes,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._notes.map((note) => _buildNoteCard(
              note.text,
              isDeleting: _deletingNoteIds.contains(note.id),
              onDelete: () => _deleteNote(note.id),
            ),),
            ..._draftNotes.map((draft) => _buildNoteCard(draft, isDraft: true)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter new note...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            if (_draftNotes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  onPressed: _isSubmittingDrafts ? null : _submitAllDrafts,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Center(
                    child: _isSubmittingDrafts
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
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
