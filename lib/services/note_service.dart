import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';

class SupabaseNoteService {
  final _supabase = Supabase.instance.client;

  Future<List<Note>> fetchNotes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    final response = await _supabase
        .from('notes')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((item) => Note.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<Note?> addNote(String title, String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    final response = await _supabase
        .from('notes')
        .insert({
          'user_id': userId,
          'title': title,
          'content': content,
        })
        .select()
        .single();
    return Note.fromMap(response as Map<String, dynamic>);
  }

  Future<void> updateNote(Note note) async {
    await _supabase.from('notes').update({
      'title': note.title,
      'content': note.content,
    }).eq('id', note.id);
  }

  Future<void> deleteNote(String noteId) async {
    await _supabase.from('notes').delete().eq('id', noteId);
  }
}
