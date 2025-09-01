import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'name_entry_screen.dart';

class BasicInfoIntroScreen extends StatelessWidget {
  const BasicInfoIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // Main content centered
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "You're one of a kind.\nYour profile should be, too.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Cute blob placeholder
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: AspectRatio(
                      aspectRatio: 3/2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1ECF5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            size: 48,
                            color: Color(0xFF6B46C1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NameEntryScreen(),
                      ),
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
                    'Enter basic info',
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


