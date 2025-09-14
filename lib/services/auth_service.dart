import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'profile_service.dart'; // Make sure this path is correct

class AuthService {
  static final _supabase = Supabase.instance.client;
  static final _profileService = ProfileService();

  /// Get the current user from the Supabase session.
  static User? get currentUser => _supabase.auth.currentUser;

  /// A stream that notifies of authentication state changes.
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// Signs in a user with their email and password.
  static Future<AuthResponse> signInWithEmail(
      String email, String password) async {
    try {
      developer.log('AuthService: Attempting to sign in with email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      developer.log(
          'AuthService: Sign in successful for user: ${response.user?.id}');
      return response;
    } on AuthException catch (e) {
      developer.log('AuthService: Error during sign in: ${e.message}',
          error: e);
      rethrow;
    } catch (e) {
      developer.log('AuthService: Unexpected error during sign in', error: e);
      rethrow;
    }
  }

  /// Signs up a new user and creates a corresponding profile.
  static Future<AuthResponse> signUpWithEmail(
      String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // FIX: Corrected method name from 'Profile' to 'upsertProfile'
        await _profileService.upsertProfile(
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

  /// Signs out the current user.
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

  /// Sends a password reset email to the user.
  static Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        // IMPORTANT: Replace with your actual deep link redirect URL
        // redirectTo: 'com.example.yourapp://login-callback/reset-password',
      );
      developer.log('Password reset email sent to: $email');
    } on AuthException catch (e) {
      developer.log('Auth error during password reset: ${e.message}', error: e);
      rethrow;
    } catch (e) {
      developer.log('Error during password reset', error: e);
      rethrow;
    }
  }
}
