import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class ProfileService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      developer.log('Fetching profile for user: $userId');
      final response = await _supabase
          .from('profiles')
          .select('id, username, bio, avatar_url')
          .eq('id', userId)
          .single();
      developer.log('Profile fetched successfully: $response');
      return response;
    } catch (e) {
      // Handle case where profile might not exist yet for the user
      if (e is PostgrestException) {
        if (e.code == 'PGRST116') {
          developer.log('Profile not found for user $userId', error: e);
          return null;
        }
        developer.log('Database error fetching profile: ${e.message}',
            error: e);
        throw Exception('Database error: ${e.message}');
      }
      developer.log('Error fetching profile for user $userId: $e', error: e);
      throw Exception('Failed to fetch profile: $e');
    }
  }

  Future<void> createProfile(
      {required String userId, required String username}) async {
    try {
      developer
          .log('Creating profile for user: $userId with username: $username');
      await _supabase
          .from('profiles')
          .insert({'id': userId, 'username': username});
      developer.log('Profile created successfully');
    } catch (e) {
      if (e is PostgrestException) {
        developer.log('Database error creating profile: ${e.message}',
            error: e);
        throw Exception('Database error: ${e.message}');
      }
      developer.log('Error creating profile for user $userId: $e', error: e);
      throw Exception('Failed to create profile: $e');
    }
  }

  Future<void> updateUsername(
      {required String userId, required String username}) async {
    try {
      developer.log('Updating username for user: $userId to: $username');
      await _supabase
          .from('profiles')
          .update({'username': username}).eq('id', userId);
      developer.log('Username updated successfully');
    } catch (e) {
      if (e is PostgrestException) {
        developer.log('Database error updating username: ${e.message}',
            error: e);
        throw Exception('Database error: ${e.message}');
      }
      developer.log('Error updating username for user $userId: $e', error: e);
      throw Exception('Failed to update username: $e');
    }
  }

  Future<void> updateBio({required String userId, required String bio}) async {
    try {
      developer.log('Updating bio for user: $userId');
      await _supabase.from('profiles').update({'bio': bio}).eq('id', userId);
      developer.log('Bio updated successfully');
    } catch (e) {
      if (e is PostgrestException) {
        developer.log('Database error updating bio: ${e.message}', error: e);
        throw Exception('Database error: ${e.message}');
      }
      developer.log('Error updating bio for user $userId: $e', error: e);
      throw Exception('Failed to update bio: $e');
    }
  }

  Future<void> updateAvatarUrl(
      {required String userId, required String avatarUrl}) async {
    try {
      developer.log('Updating avatar_url for user: $userId');
      await _supabase
          .from('profiles')
          .update({'avatar_url': avatarUrl}).eq('id', userId);
      developer.log('Avatar URL updated successfully');
    } catch (e) {
      if (e is PostgrestException) {
        developer.log('Database error updating avatar_url: ${e.message}',
            error: e);
        throw Exception('Database error: ${e.message}');
      }
      developer.log('Error updating avatar_url for user $userId: $e', error: e);
      throw Exception('Failed to update avatar_url: $e');
    }
  }

  Future<void> updateProfile(
      {required String userId,
      String? username,
      String? bio,
      String? avatarUrl}) async {
    final updateData = <String, dynamic>{};
    if (username != null) updateData['username'] = username;
    if (bio != null) updateData['bio'] = bio;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
    if (updateData.isEmpty) return;
    try {
      developer.log('Updating profile for user: $userId');
      await _supabase.from('profiles').update(updateData).eq('id', userId);
      developer.log('Profile updated successfully');
    } catch (e) {
      if (e is PostgrestException) {
        developer.log('Database error updating profile: ${e.message}',
            error: e);
        throw Exception('Database error: ${e.message}');
      }
      developer.log('Error updating profile for user $userId: $e', error: e);
      throw Exception('Failed to update profile: $e');
    }
  }
}
