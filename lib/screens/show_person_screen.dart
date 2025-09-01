import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pick_media_screen.dart';

class ShowPersonScreen extends StatefulWidget {
  const ShowPersonScreen({super.key});

  @override
  State<ShowPersonScreen> createState() => _ShowPersonScreenState();
}

class _ShowPersonScreenState extends State<ShowPersonScreen> {

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
                  'Show off the person behind the profile with pics, videos.',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 44,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  height: 260,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFF5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE7E3E7)),
                  ),
                  child: Icon(Icons.insert_emoticon_outlined, size: 96, color: Colors.black.withOpacity(0.6)),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PickMediaScreen(),
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
                    'Fill out your profile',
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


