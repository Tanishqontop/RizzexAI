import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class SafetyService {
  final _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  Future<Set<String>> getBlockedUserIds() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return {};

    try {
      final response = await _supabase
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', currentUserId);

      return (response as List)
          .map((row) => row['blocked_id'] as String)
          .toSet();
    } catch (e) {
      developer.log('Could not load blocks (table may be missing): $e');
      return {};
    }
  }

  Future<Set<String>> getUsersWhoBlockedMe() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return {};

    try {
      final response = await _supabase
          .from('blocks')
          .select('blocker_id')
          .eq('blocked_id', currentUserId);

      return (response as List)
          .map((row) => row['blocker_id'] as String)
          .toSet();
    } catch (e) {
      developer.log('Could not load blocks (table may be missing): $e');
      return {};
    }
  }

  Future<Set<String>> getHiddenUserIds() async {
    final blocked = await getBlockedUserIds();
    final blockedBy = await getUsersWhoBlockedMe();
    return {...blocked, ...blockedBy};
  }

  Future<void> blockUser(String blockedUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    if (currentUserId == blockedUserId) {
      throw Exception('You cannot block yourself');
    }

    await _supabase.from('blocks').upsert({
      'blocker_id': currentUserId,
      'blocked_id': blockedUserId,
    }, onConflict: 'blocker_id,blocked_id');

    await _removeMatchWith(blockedUserId);
    developer.log('Blocked user $blockedUserId');
  }

  Future<void> _removeMatchWith(String otherUserId) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    final ids = [currentUserId, otherUserId]..sort();
    await _supabase
        .from('matches')
        .delete()
        .eq('user1_id', ids[0])
        .eq('user2_id', ids[1]);
  }

  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? details,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    if (currentUserId == reportedUserId) {
      throw Exception('You cannot report yourself');
    }

    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw Exception('Please select a reason');
    }

    await _supabase.from('reports').insert({
      'reporter_id': currentUserId,
      'reported_id': reportedUserId,
      'reason': trimmedReason,
      'details': details?.trim().isEmpty == true ? null : details?.trim(),
    });

    developer.log('Reported user $reportedUserId');
  }
}
