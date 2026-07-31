import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/received_super_like.dart';
import '../models/user.dart' as app_user;

class SuperLikeService {
  static const int weeklyLimit = 2;

  final _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  DateTime get _startOfWeek {
    final now = DateTime.now();
    final daysFromMonday = now.weekday - DateTime.monday;
    final monday = now.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }

  Future<int> getRemainingSuperLikesThisWeek() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return 0;

    final used = await _countSuperLikesSentThisWeek(currentUserId);
    return (weeklyLimit - used).clamp(0, weeklyLimit);
  }

  Future<int> _countSuperLikesSentThisWeek(String swiperId) async {
    final response = await _supabase
        .from('swipes')
        .select('id')
        .eq('swiper_id', swiperId)
        .eq('action', 'super_like')
        .gte('created_at', _startOfWeek.toUtc().toIso8601String());

    return (response as List).length;
  }

  Future<bool> canSendSuperLike({required String targetUserId}) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return false;

    final existing = await _supabase
        .from('swipes')
        .select('action')
        .eq('swiper_id', currentUserId)
        .eq('target_id', targetUserId)
        .maybeSingle();

    if (existing != null && existing['action'] == 'super_like') {
      return true;
    }

    return await getRemainingSuperLikesThisWeek() > 0;
  }

  Future<void> ensureCanSendSuperLike({required String targetUserId}) async {
    final allowed = await canSendSuperLike(targetUserId: targetUserId);
    if (!allowed) {
      throw Exception(
        'You have used all $weeklyLimit Super Likes for this week',
      );
    }
  }

  Future<List<ReceivedSuperLike>> getReceivedSuperLikes() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('swipes')
        .select()
        .eq('target_id', currentUserId)
        .eq('action', 'super_like')
        .order('created_at', ascending: false);

    final results = <ReceivedSuperLike>[];
    for (final row in response as List) {
      final swiperId = row['swiper_id'] as String;
      final profile = await _fetchProfile(swiperId);
      if (profile == null) continue;

      results.add(ReceivedSuperLike(
        swipeId: row['id'] as String,
        swiperId: swiperId,
        swiper: profile,
        createdAt: DateTime.parse(row['created_at'] as String),
      ));
    }

    return results;
  }

  Future<Map<String, DateTime>> getSuperLikeTimestampsBySwiper() async {
    final received = await getReceivedSuperLikes();
    return {
      for (final item in received) item.swiperId: item.createdAt,
    };
  }

  Future<app_user.User?> _fetchProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return app_user.User.fromMap(response);
    } catch (e) {
      developer.log('Could not load super like profile for $userId: $e');
      return null;
    }
  }
}
