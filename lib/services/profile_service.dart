import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class ProfileService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      developer.log('Fetching profile for user: $userId');
      final response = await _supabase
          .from('profiles')
          .select('id, username')
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
}
