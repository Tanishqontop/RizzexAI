import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // NEW: Import Supabase
import '../services/profile_service.dart'; // NEW: Import ProfileService
import 'profile_details_screen.dart';

class NotificationPromptScreen extends StatefulWidget {
  const NotificationPromptScreen({super.key});

  @override
  State<NotificationPromptScreen> createState() =>
      _NotificationPromptScreenState();
}

class _NotificationPromptScreenState extends State<NotificationPromptScreen> {
  // NEW: Add service and user variables
  final _profileService = ProfileService();
  final _currentUser = Supabase.instance.client.auth.currentUser;
  bool _isLoading = false;

  // NEW: A single, unified method to handle the user's choice
  Future<void> _updateNotificationPreference(bool enable) async {
    if (_currentUser == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // If the user wants to enable notifications, request permission from the OS
      if (enable) {
        await Permission.notification.request();
      }

      // Save the user's choice (true or false) to the database
      await _profileService.upsertProfile(
        userId: _currentUser!.id,
        notificationsEnabled: enable,
      );

      // After saving, navigate to the next screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProfileDetailsScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preference: $e')),
        );
      }
      // Ensure loading state is turned off on error
      setState(() => _isLoading = false);
    }
    // Note: We don't turn off loading on success because the screen is removed
  }

  // Your dialog now just confirms the choice before calling the save function
  void _showDisableConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Are you sure?'),
        content: const Text(
            'Disabling notifications means you might miss important messages from matches.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Call the save function with 'false'
              _updateNotificationPreference(false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Use a different color for emphasis
              foregroundColor: Colors.white,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Never miss a message from someone great',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton(
                                  // Call the save function with 'true'
                                  onPressed: () =>
                                      _updateNotificationPreference(true),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFF6B46C1)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Enable notifications',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6B46C1),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton(
                                  // Show the confirmation dialog before saving 'false'
                                  onPressed: _showDisableConfirmation,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFF6B46C1)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Disable notifications',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6B46C1),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
