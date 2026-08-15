import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/user.dart' as app_user;
import '../models/user_match.dart';
import 'super_like_service.dart';
import 'safety_service.dart';

class MatchService {
  final _supabase = Supabase.instance.client;
  final SuperLikeService _superLikeService = SuperLikeService();
  final SafetyService _safetyService = SafetyService();

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Records a swipe and returns a new match when both users have liked each other.
  Future<UserMatch?> recordSwipe({
    required String targetUserId,
    required bool isLike,
    bool superLike = false,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (superLike) {
      await _superLikeService.ensureCanSendSuperLike(
        targetUserId: targetUserId,
      );
    }

    final action = superLike
        ? 'super_like'
        : isLike
            ? 'like'
            : 'pass';

    await _supabase.from('swipes').upsert({
      'swiper_id': currentUserId,
      'target_id': targetUserId,
      'action': action,
    }, onConflict: 'swiper_id,target_id');

    if (!isLike && !superLike) {
      return null;
    }

    final reciprocal = await _supabase
        .from('swipes')
        .select()
        .eq('swiper_id', targetUserId)
        .eq('target_id', currentUserId)
        .maybeSingle();

    if (reciprocal == null) return null;

    final reciprocalAction = reciprocal['action'] as String?;
    if (reciprocalAction != 'like' && reciprocalAction != 'super_like') {
      return null;
    }

    return _createMatch(currentUserId, targetUserId);
  }

  Future<UserMatch?> createMatchWith(String otherUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return null;
    return _createMatch(currentUserId, otherUserId);
  }

  Future<UserMatch?> _createMatch(String userId1, String userId2) async {
    final ids = [userId1, userId2]..sort();
    final user1Id = ids[0];
    final user2Id = ids[1];

    final existing = await _supabase
        .from('matches')
        .select()
        .eq('user1_id', user1Id)
        .eq('user2_id', user2Id)
        .maybeSingle();

    if (existing != null) {
      final otherUserId = userId1 == _currentUserId ? user2Id : user1Id;
      final profile = await _fetchProfile(otherUserId);
      if (profile == null) return null;
      return UserMatch(
        id: existing['id'] as String,
        user1Id: user1Id,
        user2Id: user2Id,
        matchedUser: profile,
        createdAt: DateTime.parse(existing['created_at'] as String),
        receivedSuperLike: false,
      );
    }

    final inserted = await _supabase
        .from('matches')
        .insert({'user1_id': user1Id, 'user2_id': user2Id})
        .select()
        .single();

    final otherUserId = userId1 == _currentUserId ? user2Id : user1Id;
    final profile = await _fetchProfile(otherUserId);
    if (profile == null) return null;

    developer.log('New match created: $user1Id <-> $user2Id');

    return UserMatch(
      id: inserted['id'] as String,
      user1Id: user1Id,
      user2Id: user2Id,
      matchedUser: profile,
      createdAt: DateTime.parse(inserted['created_at'] as String),
      receivedSuperLike: false,
    );
  }

  Future<List<UserMatch>> getMatches() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('matches')
        .select()
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
        .order('created_at', ascending: false);

    final superLikeTimes = await _loadSuperLikeTimes();
    final hiddenIds = await _safetyService.getHiddenUserIds();

    final matches = <UserMatch>[];
    for (final row in response as List) {
      final user1Id = row['user1_id'] as String;
      final user2Id = row['user2_id'] as String;
      final matchId = row['id'] as String;
      final otherUserId =
          currentUserId == user1Id ? user2Id : user1Id;

      if (hiddenIds.contains(otherUserId)) continue;

      final profile = await _fetchProfile(otherUserId);
      if (profile == null) continue;

      final lastMsg = await _fetchLastMessage(matchId);

      String? lastMessagePreview;
      if (lastMsg != null) {
        final type = lastMsg['message_type'] as String? ?? 'text';
        final content = lastMsg['content'] as String? ?? '';
        if (type == 'image') {
          final viewOnce = _parseBool(lastMsg['view_once']);
          lastMessagePreview = content.isNotEmpty
              ? '📷 $content'
              : viewOnce
                  ? '📷 Photo · View once'
                  : '📷 Photo';
        } else {
          lastMessagePreview = content.isNotEmpty ? content : null;
        }
      }

      final superLikeAt = superLikeTimes[otherUserId];

      matches.add(UserMatch(
        id: matchId,
        user1Id: user1Id,
        user2Id: user2Id,
        matchedUser: profile,
        createdAt: DateTime.parse(row['created_at'] as String),
        lastMessage: lastMessagePreview,
        lastMessageAt: lastMsg?['created_at'] != null
            ? DateTime.parse(lastMsg!['created_at'] as String)
            : null,
        lastMessageSenderId: lastMsg?['sender_id'] as String?,
        receivedSuperLike: superLikeAt != null,
        superLikeAt: superLikeAt,
      ));
    }

    matches.sort((a, b) {
      if (a.hasReceivedSuperLike != b.hasReceivedSuperLike) {
        return a.hasReceivedSuperLike ? -1 : 1;
      }
      if (a.hasReceivedSuperLike && b.hasReceivedSuperLike) {
        final aSuper = a.superLikeAt ?? a.createdAt;
        final bSuper = b.superLikeAt ?? b.createdAt;
        final superCompare = bSuper.compareTo(aSuper);
        if (superCompare != 0) return superCompare;
      }
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    return matches;
  }

  Future<Map<String, DateTime>> _loadSuperLikeTimes() async {
    try {
      return await _superLikeService.getSuperLikeTimestampsBySwiper();
    } catch (e) {
      developer.log('Could not load super like timestamps: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>?> _fetchLastMessage(String matchId) async {
    try {
      return await _supabase
          .from('messages')
          .select('content, created_at, message_type, view_once, sender_id')
          .eq('match_id', matchId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      developer.log('Last message query failed, retrying without view_once: $e');
      try {
        return await _supabase
            .from('messages')
            .select('content, created_at, message_type, sender_id')
            .eq('match_id', matchId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
      } catch (e2) {
        developer.log('Could not load last message for match $matchId: $e2');
        return null;
      }
    }
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == 't' || normalized == '1';
    }
    return false;
  }

  Future<List<String>> getSwipedUserIds() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('swipes')
        .select('target_id')
        .eq('swiper_id', currentUserId);

    return (response as List)
        .map((row) => row['target_id'] as String)
        .toList();
  }

  /// Removes the current user's swipe on [targetUserId] and optionally the match.
  Future<void> rewindSwipe({
    required String targetUserId,
    String? matchIdToRemove,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    if (matchIdToRemove != null) {
      await _supabase.from('matches').delete().eq('id', matchIdToRemove);
    }

    await _supabase
        .from('swipes')
        .delete()
        .eq('swiper_id', currentUserId)
        .eq('target_id', targetUserId);
  }

  /// Users the current user explicitly passed on (still eligible for Discover).
  Future<void> removeMatchWith(String otherUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    final ids = [currentUserId, otherUserId]..sort();
    await _supabase
        .from('matches')
        .delete()
        .eq('user1_id', ids[0])
        .eq('user2_id', ids[1]);
  }

  Future<List<String>> getPassedUserIds() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return [];

    final response = await _supabase
        .from('swipes')
        .select('target_id')
        .eq('swiper_id', currentUserId)
        .eq('action', 'pass');

    return (response as List)
        .map((row) => row['target_id'] as String)
        .toList();
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
      try {
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();
        return app_user.User.fromBasicMap(response);
      } catch (_) {
        developer.log('Could not load profile for $userId');
        return null;
      }
    }
  }
}
