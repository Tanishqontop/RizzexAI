import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/note_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final SupabaseNoteService _noteService = SupabaseNoteService();
  List<Note> _notes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notes = await _noteService.fetchNotes();
      setState(() {
        _notes = notes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load notes: $e';
        _loading = false;
      });
    }
  }

  Future<void> _addOrEditNote({Note? note}) async {
    final result = await showDialog<Note>(
      context: context,
      builder: (context) => _NoteDialog(note: note),
    );
    if (result != null) {
      if (note == null) {
        await _noteService.addNote(result.title, result.content);
      } else {
        await _noteService.updateNote(result);
      }
      await _fetchNotes();
    }
  }

  Future<void> _deleteNote(Note note) async {
    await _noteService.deleteNote(note.id);
    await _fetchNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchNotes,
                  child: _notes.isEmpty
                      ? const Center(
                          child: Text('No notes yet. Tap + to add one!'))
                      : ListView.builder(
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            return Dismissible(
                              key: Key(note.id),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 24),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              direction: DismissDirection.startToEnd,
                              onDismissed: (_) => _deleteNote(note),
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(note.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.red),
                                    onPressed: () => _addOrEditNote(note: note),
                                  ),
                                  onTap: () => _showNoteDetail(note),
                                ),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditNote(),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Note',
      ),
    );
  }

  void _showNoteDetail(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note.title),
        content: SingleChildScrollView(child: Text(note.content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  final Note? note;
  const _NoteDialog({this.note});

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'Add Note' : 'Edit Note'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              maxLength: 50,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 5,
              minLines: 2,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleController.text.trim();
            final content = _contentController.text.trim();
            if (title.isEmpty || content.isEmpty) return;
            Navigator.pop(
              context,
              Note(
                id: widget.note?.id ?? '',
                userId: widget.note?.userId ?? '',
                title: title,
                content: content,
                createdAt: widget.note?.createdAt ?? DateTime.now(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(widget.note == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
