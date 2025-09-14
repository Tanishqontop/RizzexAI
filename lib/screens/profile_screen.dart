import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import 'dob_entry_screen.dart'; // Make sure this import path is correct

class NameEntryScreen extends StatefulWidget {
  const NameEntryScreen({super.key});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  final _focusNode = FocusNode();

  final _profileService = ProfileService();
  final _currentUser = Supabase.instance.client.auth.currentUser;

  bool _pressed = false;
  bool _loading = false;

  // This getter controls if the button is enabled.
  // It's only true if the first name field is not empty.
  bool get _isValid => _firstController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // This listener forces the widget to rebuild every time the text changes,
    // which re-evaluates `_isValid` and updates the button's state.
    _firstController.addListener(() => setState(() {}));

    // Automatically focus the first name field when the screen loads.
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

  Future<void> _saveNameAndContinue() async {
    // Guard clause to prevent running if the button is disabled or user is missing.
    if (!_isValid || _currentUser == null || _loading) return;

    setState(() => _loading = true);

    try {
      // Use the single, efficient `upsertProfile` method to update the names.
      await _profileService.upsertProfile(
        userId: _currentUser!.id,
        firstName: _firstController.text.trim(),
        lastName: _lastController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DobEntryScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save name: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG: This line will print the state of the button to your console.
    print('First Name: "${_firstController.text}", Is Valid: $_isValid');

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
                            hintStyle:
                                GoogleFonts.inter(color: Colors.grey[500]),
                            border: const UnderlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _lastController,
                          decoration: InputDecoration(
                            hintText: 'Last name',
                            hintStyle:
                                GoogleFonts.inter(color: Colors.grey[500]),
                            border: const UnderlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (_isValid) _saveNameAndContinue();
                          },
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
              child: InkWell(
                borderRadius: BorderRadius.circular(36),
                onTap: _isValid && !_loading ? _saveNameAndContinue : null,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapCancel: () => setState(() => _pressed = false),
                onTapUp: (_) => setState(() => _pressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _isValid
                        ? (_pressed
                            ? const Color(0xFF5A3BB1) // Darker purple
                            : const Color(0xFF6B46C1)) // Normal purple
                        : Colors.grey[200], // Disabled color
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(18.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _isValid ? Colors.white : Colors.grey[600],
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
