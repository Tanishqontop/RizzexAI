import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dob_entry_screen.dart';

class NameEntryScreen extends StatefulWidget {
  const NameEntryScreen({super.key});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _lastController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _pressed = false;

  bool get _isValid => _firstController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _firstController.addListener(() => setState(() {}));
    // Auto-focus the text field when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
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
                          "What's your name?",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _firstController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: 'First name (required)',
                            hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                            border: const UnderlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _lastController,
                          decoration: InputDecoration(
                            hintText: 'Last name',
                            hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
                            border: const UnderlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Last name is optional, and only shared with matches. Why?',
                          style: GoogleFonts.inter(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) {
                  setState(() => _pressed = false);
                  if (_isValid) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DobEntryScreen()),
                    );
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _isValid
                        ? (_pressed ? const Color(0xFF5A3BB1) : const Color(0xFF6B46C1))
                        : (_pressed ? const Color(0xFFF0EDF2) : Colors.white),
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
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _isValid ? Colors.white : const Color(0xFF1F1F1F),
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