import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class SafetyService {
  final _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// Users the current user blocked (only they initiated).
  Future<Set<String>> getBlockedUserIds() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return {};

    final response = await _supabase
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', currentUserId);

    return (response as List)
        .map((row) => row['blocked_id'] as String)
        .toSet();
  }

  /// Users the current user reported (only they initiated).
  Future<Set<String>> getReportedUserIds() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return {};

    final response = await _supabase
        .from('reports')
        .select('reported_id')
        .eq('reporter_id', currentUserId);

    return (response as List)
        .map((row) => row['reported_id'] as String)
        .toSet();
  }

  /// IDs hidden from the **current user's** feed and chats only.
  /// Other users can still see those profiles.
  Future<Set<String>> getHiddenUserIds() async {
    try {
      final blocked = await getBlockedUserIds();
      final reported = await getReportedUserIds();
      return {...blocked, ...reported};
    } on PostgrestException catch (e) {
      developer.log('Could not load safety hidden users: ${e.message}', error: e);
      return {};
    }
  }

  Future<void> blockUser(
    String blockedUserId, {
    String? matchId,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    if (currentUserId == blockedUserId) {
      throw Exception('You cannot block yourself');
    }

    try {
      await _supabase.from('blocks').insert({
        'blocker_id': currentUserId,
        'blocked_id': blockedUserId,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') {
        throw Exception(e.message);
      }
    }

    await _removeMatchWith(blockedUserId, matchId: matchId);

    developer.log('Blocked user $blockedUserId');
  }

  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? details,
    String? matchId,
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

    // Hide only for this reporter; do not platform-block the profile.
    await _removeMatchWith(reportedUserId, matchId: matchId);

    developer.log('Reported user $reportedUserId');
  }

  Future<void> _removeMatchWith(
    String otherUserId, {
    String? matchId,
  }) async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) return;

    if (matchId != null && matchId.isNotEmpty) {
      try {
        await _supabase.from('matches').delete().eq('id', matchId);
        return;
      } on PostgrestException catch (e) {
        developer.log('Match delete by id failed: ${e.message}', error: e);
      }
    }

    final ids = [currentUserId, otherUserId]..sort();
    try {
      await _supabase
          .from('matches')
          .delete()
          .eq('user1_id', ids[0])
          .eq('user2_id', ids[1]);
    } on PostgrestException catch (e) {
      developer.log('Match removal failed: ${e.message}', error: e);
    }
  }
}
