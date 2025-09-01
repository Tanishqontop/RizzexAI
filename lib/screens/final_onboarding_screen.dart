import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class FinalOnboardingScreen extends StatefulWidget {
  const FinalOnboardingScreen({super.key, required this.uploadedCount});

  final int uploadedCount;

  @override
  State<FinalOnboardingScreen> createState() => _FinalOnboardingScreenState();
}

class _FinalOnboardingScreenState extends State<FinalOnboardingScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 48),
                Text(
                  "All done! Let's see who catches your eye.",
                  style: GoogleFonts.playfairDisplay(
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
                const SizedBox(height: 120),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Start sending likes',
                    style: GoogleFonts.inter(
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


