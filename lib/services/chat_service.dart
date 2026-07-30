import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';

class ChatService {
  static const _chatMediaBucket = 'chat_media';

  final _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  Stream<List<ChatMessage>> watchMessages(String matchId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('created_at')
        .map((rows) {
          final messages = rows.map(ChatMessage.fromMap).toList();
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return messages;
        });
  }

  Future<List<ChatMessage>> getMessages(String matchId) async {
    final response = await _supabase
        .from('messages')
        .select()
        .eq('match_id', matchId)
        .order('created_at', ascending: true);

    return (response as List).map((row) => ChatMessage.fromMap(row)).toList();
  }

  Future<ChatMessage> sendMessage({
    required String matchId,
    required String content,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final response = await _supabase.from('messages').insert({
      'match_id': matchId,
      'sender_id': currentUserId,
      'content': trimmed,
      'message_type': 'text',
    }).select().single();

    return ChatMessage.fromMap(response);
  }

  Future<String> uploadChatImage({
    required String matchId,
    required File file,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final extension = file.path.split('.').last.toLowerCase();
    final safeExt = ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(extension)
        ? extension
        : 'jpg';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$safeExt';
    final filePath = '$matchId/$currentUserId/$fileName';

    await _supabase.storage.from(_chatMediaBucket).upload(
          filePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return _supabase.storage.from(_chatMediaBucket).getPublicUrl(filePath);
  }

  Future<ChatMessage> sendImageMessage({
    required String matchId,
    required File file,
    bool viewOnce = false,
    String? caption,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final mediaUrl = await uploadChatImage(matchId: matchId, file: file);

    final response = await _supabase.from('messages').insert({
      'match_id': matchId,
      'sender_id': currentUserId,
      'content': caption?.trim() ?? '',
      'message_type': 'image',
      'media_url': mediaUrl,
      'view_once': viewOnce,
    }).select().single();

    return ChatMessage.fromMap(response);
  }

  Future<void> markViewOnceOpened(String messageId) async {
    await _supabase.rpc(
      'consume_view_once_message',
      params: {'p_message_id': messageId},
    );
  }
}
