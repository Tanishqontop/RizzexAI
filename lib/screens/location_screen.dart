import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pronouns_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isNextPressed = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _locationController.addListener(_onTextChanged);
    // Auto-focus the text field when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _locationController.removeListener(_onTextChanged);
    _locationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _locationController.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE7E3E7)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.place_outlined, color: Color(0xFF1F1F1F)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Where do you live?',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 34,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F1F1F),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 380,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE7E3E7)),
                      image: const DecorationImage(
                        image: AssetImage('assets/round-icons-lEvCd62sbKs-unsplash.jpg'),
                        fit: BoxFit.fill,
                        alignment: Alignment.center,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: 16,
                          top: 16,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.my_location_outlined, color: Color(0xFF1F1F1F)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _locationController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'District, State, Country',
                      hintStyle: GoogleFonts.inter(color: const Color(0xFF6D6A6D)),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF1F1F1F)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF1F1F1F)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() => _isNextPressed = true);
                },
                onTapCancel: () {
                  setState(() => _isNextPressed = false);
                },
                onTapUp: (_) {
                  setState(() => _isNextPressed = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PronounsScreen()),
                  );
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _hasText 
                        ? (_isNextPressed ? const Color(0xFF5A3BB1) : const Color(0xFF6B46C1))
                        : (_isNextPressed ? const Color(0xFFF0EDF2) : Colors.white),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE7E3E7)),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded, 
                    color: _hasText ? Colors.white : const Color(0xFF1F1F1F)
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