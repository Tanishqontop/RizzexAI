import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'job_title_screen.dart';

class WorkScreen extends StatefulWidget {
  const WorkScreen({super.key});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _visibleOnProfile = true;
  bool _pressed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.work_outline, size: 40, color: Color(0xFF1F1F1F)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Where do you work?',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 34,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Workplace',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF9A979A), fontSize: 22, fontStyle: FontStyle.italic),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1F1F1F))),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1F1F1F))),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Checkbox(
                      value: _visibleOnProfile,
                      activeColor: const Color(0xFF6B46C1),
                      onChanged: (v) => setState(() => _visibleOnProfile = v ?? true),
                    ),
                    Text('Visible on profile', style: GoogleFonts.inter(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) {
                  setState(() => _pressed = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JobTitleScreen()),
                  );
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _pressed ? const Color(0xFFF0EDF2) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE7E3E7)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF1F1F1F)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


