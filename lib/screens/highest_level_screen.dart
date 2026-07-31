import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // NEW: Import Supabase
import '../services/profile_service.dart';
import '../widgets/onboarding_skip_button.dart';
import 'religious_belief_screen.dart';

class HighestLevelScreen extends StatefulWidget {
  const HighestLevelScreen({super.key});

  @override
  State<HighestLevelScreen> createState() => _HighestLevelScreenState();
}

class _HighestLevelScreenState extends State<HighestLevelScreen> {
  // NEW: Add service, user, and loading state variables
  final _profileService = ProfileService();
  final _currentUser = Supabase.instance.client.auth.currentUser;
  bool _loading = false;

  String? _selected;
  bool _pressed = false;
  bool _visibleOnProfile = true;

  static const List<String> _options = [
    'Secondary school',
    'Undergrad',
    'Postgrad',
    'Prefer not to say'
  ];

  // NEW: Method to save data to Supabase and then navigate
  Future<void> _saveEducationLevelAndContinue() async {
    if (_selected == null || _currentUser == null || _loading) return;

    setState(() => _loading = true);

    try {
      await _profileService.upsertProfile(
        userId: _currentUser!.id,
        educationLevel: _selected,
        educationLevelVisible: _visibleOnProfile,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReligiousBeliefScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save education level: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _skipAndContinue() {
    if (!mounted || _loading) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReligiousBeliefScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selected != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: OnboardingSkipLayout(
          onSkip: _skipAndContinue,
          skipEnabled: !_loading,
          child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.school_outlined,
                        size: 40, color: Color(0xFF1F1F1F)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "What's the highest level you attained?",
                        style: AppFonts.display(
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
                ..._options.map((o) => _EduTile(
                      label: o,
                      selected: _selected == o,
                      onTap: () => setState(() => _selected = o),
                    )),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _visibleOnProfile,
                      activeColor: const Color(0xFF6B46C1),
                      onChanged: (v) =>
                          setState(() => _visibleOnProfile = v ?? true),
                    ),
                    Text('Visible on profile',
                        style: AppFonts.geist(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 100), // Space for button
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
                  // MODIFIED: Call the save function
                  _saveEducationLevelAndContinue();
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: hasSelection
                        ? (_pressed
                            ? const Color(0xFF5A3BB1)
                            : const Color(0xFF6B46C1))
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
                  // MODIFIED: Show loading indicator
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(18.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.arrow_forward_ios_rounded,
                          color: hasSelection
                              ? Colors.white
                              : const Color(0xFF1F1F1F)),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _EduTile extends StatelessWidget {
  const _EduTile(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE7E3E7))),
        ),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: AppFonts.geist(
                        fontSize: 18, color: const Color(0xFF1F1F1F)))),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD6D3D6)),
                color: selected ? const Color(0xFF6B46C1) : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            )
          ],
        ),
      ),
    );
  }
}
