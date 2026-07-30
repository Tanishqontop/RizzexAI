import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../models/user.dart' as app_user;
import '../models/user_match.dart';
import 'match_service.dart';

class FeedService {
  final _supabase = Supabase.instance.client;
  final MatchService _matchService = MatchService();

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

  /// Fetches potential matches for the current user
  Future<List<app_user.User>> getPotentialMatches({
    int limit = 10,
    int offset = 0,
  }) async {
    return _guardedCall(() async {
      try {
        final currentUserId = _supabase.auth.currentUser?.id;
        if (currentUserId == null) {
          throw Exception('User not authenticated');
        }

        developer.log('Fetching potential matches for user: $currentUserId');

        final swipedIds = await _matchService.getSwipedUserIds();

        var query = _supabase
            .from('profiles')
            .select()
            .neq('id', currentUserId) // Exclude current user
            .order('updated_at', ascending: false)
            .range(offset, offset + limit - 1);

        // Add basic filtering based on user preferences
        // Note: In a real app, you'd implement more complex matching logic
        // For now, we'll just get all profiles except the current user

        final response = await query;
        
        developer.log('Raw response from database: $response');
        developer.log('Number of profiles found: ${response.length}');
        
        if (response.isEmpty) {
          developer.log('No profiles found in database');
          return [];
        }
        
        // Log the first profile to see what fields are available
        if (response.isNotEmpty) {
          developer.log('First profile structure: ${response.first}');
        }
        
        final users = <app_user.User>[];
        
        for (final profile in response) {
          try {
            final profileId = profile['id'] as String;
            if (swipedIds.contains(profileId)) continue;

            // Try the full mapping first
            final user = app_user.User.fromMap(profile);
            users.add(user);
          } catch (e) {
            developer.log('Error mapping profile with full fields: $e');
            try {
              // Fallback to basic mapping
              final user = app_user.User.fromBasicMap(profile);
              users.add(user);
              developer.log('Successfully mapped profile with basic fields');
            } catch (e2) {
              developer.log('Error mapping profile with basic fields: $e2');
              // Skip this profile
            }
          }
        }

        developer.log('Successfully mapped ${users.length} users');
        return users;
      } catch (e) {
        developer.log('Error fetching potential matches: $e');
        rethrow;
      }
    });
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
