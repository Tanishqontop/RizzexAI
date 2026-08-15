import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/user.dart' as app_user;
import '../models/user_match.dart';
import 'match_service.dart';
import 'safety_service.dart';

class FeedService {
  final _supabase = Supabase.instance.client;
  final MatchService _matchService = MatchService();
  final SafetyService _safetyService = SafetyService();

  /// Private helper to execute Supabase calls with standardized error handling.
  Future<T> _guardedCall<T>(Future<T> Function() function) async {
    try {
      return await function();
    } on PostgrestException catch (e) {
      developer.log('Database error: ${e.message}', error: e);
      throw Exception('A database error occurred: ${e.code}');
    } catch (e) {
      developer.log('An unexpected error occurred: $e', error: e);
      throw Exception('An unexpected error occurred.');
    }
  }

  /// Fetches potential matches for the current user (complete profiles only).
  Future<List<app_user.User>> getPotentialMatches({
    int limit = 10,
    int offset = 0,
  }) async {
    return _guardedCall(() async {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      developer.log('Fetching potential matches for user: $currentUserId');

      final swipedIds = await _matchService.getSwipedUserIds();
      final hiddenIds = await _safetyService.getHiddenUserIds();
      final users = <app_user.User>[];
      var pageOffset = offset;
      const pageSize = 40;

      while (users.length < limit) {
        final response = await _supabase
            .from('profiles')
            .select()
            .neq('id', currentUserId)
            .order('updated_at', ascending: false)
            .range(pageOffset, pageOffset + pageSize - 1);

        if (response.isEmpty) break;

        for (final profile in response) {
          final profileId = profile['id'] as String;
          if (swipedIds.contains(profileId)) continue;
          if (hiddenIds.contains(profileId)) continue;

          final user = _mapProfile(profile);
          if (user == null || !_isDiscoverable(user)) continue;

          users.add(user);
          if (users.length >= limit) break;
        }

        if (response.length < pageSize) break;
        pageOffset += pageSize;
      }

      developer.log('Feed profiles ready: ${users.length}');
      return users;
    });
  }

  /// Fetches browseable profiles for Discover (completed profiles with photos).
  /// Unlike the feed, only excludes passes — likes/super likes stay visible here.
  Future<List<app_user.User>> getDiscoverProfiles({
    int limit = 36,
  }) async {
    return _guardedCall(() async {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      developer.log('Fetching discover profiles for user: $currentUserId');

      final passedIds = await _matchService.getPassedUserIds();
      final hiddenIds = await _safetyService.getHiddenUserIds();
      final users = <app_user.User>[];
      var offset = 0;
      const pageSize = 40;

      while (users.length < limit) {
        final response = await _supabase
            .from('profiles')
            .select()
            .neq('id', currentUserId)
            .order('updated_at', ascending: false)
            .range(offset, offset + pageSize - 1);

        if (response.isEmpty) break;

        for (final profile in response) {
          final profileId = profile['id'] as String;
          if (passedIds.contains(profileId)) continue;
          if (hiddenIds.contains(profileId)) continue;

          final user = _mapProfile(profile);
          if (user == null || !_isDiscoverable(user)) continue;

          users.add(user);
          if (users.length >= limit) break;
        }

        if (response.length < pageSize) break;
        offset += pageSize;
      }

      developer.log('Discover profiles ready: ${users.length}');
      return users;
    });
  }

  app_user.User? _mapProfile(Map<String, dynamic> profile) {
    try {
      return app_user.User.fromMap(profile);
    } catch (e) {
      developer.log('Error mapping profile with full fields: $e');
      try {
        return app_user.User.fromBasicMap(profile);
      } catch (e2) {
        developer.log('Error mapping profile with basic fields: $e2');
        return null;
      }
    }
  }

  bool _isDiscoverable(app_user.User user) {
    final hasName = (user.firstName?.trim().isNotEmpty ?? false) ||
        (user.lastName?.trim().isNotEmpty ?? false) ||
        (user.username?.trim().isNotEmpty ?? false);
    return hasName && user.allPhotos.isNotEmpty;
  }

  /// Records a swipe action. Returns a match when both users liked each other.
  Future<UserMatch?> recordSwipe({
    required String targetUserId,
    required bool isLike,
    String? superLike,
  }) async {
    return _guardedCall(() async {
      try {
        developer.log(
          'Recording swipe -> $targetUserId (like: $isLike)',
        );

        return await _matchService.recordSwipe(
          targetUserId: targetUserId,
          isLike: isLike,
          superLike: superLike == 'true',
        );
      } catch (e) {
        developer.log('Error recording swipe: $e');
        rethrow;
      }
    });
  }

  /// Undoes the last swipe on a profile (used by Feed rewind).
  Future<void> rewindSwipe({
    required String targetUserId,
    String? matchIdToRemove,
  }) async {
    return _guardedCall(() async {
      await _matchService.rewindSwipe(
        targetUserId: targetUserId,
        matchIdToRemove: matchIdToRemove,
      );
    });
  }

  /// Gets the current user's profile
  Future<app_user.User?> getCurrentUserProfile() async {
    return _guardedCall(() async {
      try {
        final currentUserId = _supabase.auth.currentUser?.id;
        if (currentUserId == null) {
          return null;
        }

        final response = await _supabase
            .from('profiles')
            .select()
            .eq('id', currentUserId)
            .single();

        return app_user.User.fromMap(response);
      } catch (e) {
        developer.log('Error fetching current user profile: $e');
        return null;
      }
    });
  }

  /// Refreshes the feed with new potential matches
  Future<List<app_user.User>> refreshFeed() async {
    return getPotentialMatches(limit: 20, offset: 0);
  }

  /// Loads more profiles for pagination
  Future<List<app_user.User>> loadMoreProfiles(int currentCount) async {
    return getPotentialMatches(limit: 10, offset: currentCount);
  }
}
