import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'profile_service.dart';

class AuthService {
  static final _supabase = Supabase.instance.client;
  static final _profileService = ProfileService();

  static User? get currentUser => _supabase.auth.currentUser;

  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  static Future<AuthResponse> signInWithEmail(
      String email, String password) async {
    try {
      developer.log('AuthService: Starting sign in process');
      developer.log('AuthService: Attempting to sign in with email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      developer.log('AuthService: Sign in response received');
      developer.log('AuthService: User ID: ${response.user?.id}');
      developer.log('AuthService: User email: ${response.user?.email}');
      developer.log(
          'AuthService: Session valid: ${response.session?.accessToken != null}');

      if (response.user != null) {
        developer.log('AuthService: User profile found');
        // Get user profile
        final profile = await _supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();
        developer.log('AuthService: User profile: $profile');
      } else {
        developer.log('AuthService: No user profile found');
      }

      return response;
    } on AuthException catch (e) {
      developer.log(
          'AuthService: Authentication error during sign in: ${e.message}',
          error: e);
      rethrow;
    } catch (e) {
      developer.log('AuthService: Unexpected error during sign in', error: e);
      rethrow;
    }
  }

  static Future<AuthResponse> signUpWithEmail(
      String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create a profile for the new user
        await _profileService.createProfile(
          userId: response.user!.id,
          username: email.split('@')[0], // Use email username as default
        );
        developer.log('Profile created for new user: ${response.user?.email}');
      }

      developer.log('User signed up successfully: ${response.user?.email}');
      return response;
    } on AuthException catch (e) {
      developer.log('Authentication error during sign up: ${e.message}',
          error: e);
      rethrow;
    } catch (e) {
      developer.log('Unexpected error during sign up', error: e);
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      developer.log('User signed out successfully');
    } on AuthException catch (e) {
      developer.log('Authentication error during sign out: ${e.message}',
          error: e);
      rethrow;
    } catch (e) {
      developer.log('Unexpected error during sign out', error: e);
      rethrow;
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      developer.log('Auth error during password reset: ${e.message}', error: e);
      throw Exception('Authentication error: ${e.message}');
    } catch (e) {
      developer.log('Error during password reset', error: e);
      throw Exception('Failed to reset password: $e');
    }
  }
}
