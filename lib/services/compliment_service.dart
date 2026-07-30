import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/compliment.dart';
import '../models/user.dart' as app_user;
import '../models/user_match.dart';
import 'match_service.dart';
import 'chat_service.dart';

class ComplimentService {
  static const int dailyLimit = 2;

  final _supabase = Supabase.instance.client;
  final MatchService _matchService = MatchService();
  final ChatService _chatService = ChatService();

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  DateTime get _startOfTodayLocal {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<int> getRemainingComplimentsToday() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return 0;

    final used = await _countComplimentsSentToday(currentUserId);
    return (dailyLimit - used).clamp(0, dailyLimit);
  }

  Future<int> _countComplimentsSentToday(String senderId) async {
    final response = await _supabase
        .from('compliments')
        .select('id')
        .eq('sender_id', senderId)
        .gte('created_at', _startOfTodayLocal.toUtc().toIso8601String());

    return (response as List).length;
  }

  Future<void> sendCompliment({
    required String recipientId,
    required String message,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (currentUserId == recipientId) {
      throw Exception('You cannot compliment yourself');
    }

    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw Exception('Compliment cannot be empty');
    }

    final remaining = await getRemainingComplimentsToday();
    if (remaining <= 0) {
      throw Exception('You have used all $dailyLimit compliments for today');
    }

    await _supabase.from('compliments').insert({
      'sender_id': currentUserId,
      'recipient_id': recipientId,
      'message': trimmed,
    });

    developer.log('Compliment sent to $recipientId');
  }

  Future<List<Compliment>> getPendingReceivedCompliments() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('compliments')
        .select()
        .eq('recipient_id', currentUserId)
        .isFilter('reply', null)
        .order('created_at', ascending: false);

    final compliments = <Compliment>[];
    for (final row in response as List) {
      final compliment = Compliment.fromMap(row);
      final sender = await _fetchProfile(compliment.senderId);
      compliments.add(Compliment(
        id: compliment.id,
        senderId: compliment.senderId,
        recipientId: compliment.recipientId,
        message: compliment.message,
        createdAt: compliment.createdAt,
        sender: sender,
      ));
    }

    return compliments;
  }

  /// Reply to a compliment — creates a match and starts chat with the reply as first message.
  Future<UserMatch?> replyToCompliment({
    required String complimentId,
    required String reply,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    final trimmed = reply.trim();
    if (trimmed.isEmpty) {
      throw Exception('Reply cannot be empty');
    }

    final complimentRow = await _supabase
        .from('compliments')
        .select()
        .eq('id', complimentId)
        .eq('recipient_id', currentUserId)
        .isFilter('reply', null)
        .maybeSingle();

    if (complimentRow == null) {
      throw Exception('Compliment not found or already replied');
    }

    final senderId = complimentRow['sender_id'] as String;

    await _supabase.from('compliments').update({
      'reply': trimmed,
      'replied_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', complimentId);

    final match = await _matchService.createMatchWith(senderId);
    if (match != null) {
      await _chatService.sendMessage(
        matchId: match.id,
        content: trimmed,
      );
    }

    return match;
  }

  Future<app_user.User?> _fetchProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return app_user.User.fromMap(response);
    } catch (_) {
      return null;
    }
  }
}
