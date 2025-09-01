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
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Show off the person behind the profile with pics, videos.',
                      textAlign: TextAlign.center,
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
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: FloatingActionButton(
                  heroTag: 'show-person-next',
                  backgroundColor: const Color(0xFF6B46C1),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PickMediaScreen(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}


