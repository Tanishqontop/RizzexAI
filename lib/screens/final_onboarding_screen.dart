import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import 'auth_wrapper.dart';

class FinalOnboardingScreen extends StatefulWidget {
  const FinalOnboardingScreen({super.key, required this.uploadedCount});

  final int uploadedCount;

  @override
  State<FinalOnboardingScreen> createState() => _FinalOnboardingScreenState();
}

class _FinalOnboardingScreenState extends State<FinalOnboardingScreen> {
  bool _isFinishing = false;

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;

    setState(() => _isFinishing = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await ProfileService().upsertProfile(
          userId: userId,
          onboardingCompleted: true,
        );
      }

      if (!mounted) return;
      navigateToAuthRoot(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to finish onboarding: $e')),
        );
        setState(() => _isFinishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "All done! Let's see who catches your eye.",
                      textAlign: TextAlign.center,
                      style: AppFonts.display(
                        fontSize: 44,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Container(
                        height: 240,
                        width: 240,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EFF5),
                          borderRadius: BorderRadius.circular(120),
                          border: Border.all(color: const Color(0xFFE7E3E7)),
                        ),
                        child: const Icon(Icons.tag_faces, size: 96, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isFinishing ? null : _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isFinishing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Start sending likes',
                          style: AppFonts.geist(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


