import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pick_media_screen.dart';

class ShowPersonScreen extends StatefulWidget {
  const ShowPersonScreen({super.key});

  @override
  State<ShowPersonScreen> createState() => _ShowPersonScreenState();
}

class _ShowPersonScreenState extends State<ShowPersonScreen> {
  bool _pressed = false;

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
                  'Show off the person behind the profile with pics, videos and Prompts.',
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) {
                  setState(() => _pressed = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PickMediaScreen()),
                  );
                },
                child: Container(
                  color: _pressed ? const Color(0xFF5A3BB1) : const Color(0xFF6B46C1),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  alignment: Alignment.center,
                  child: Text('Fill out your profile', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


