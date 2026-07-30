import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // NEW: Import Supabase
import '../services/profile_service.dart'; // NEW: Import ProfileService
import 'relationship_type_screen.dart';

class DatingIntentionScreen extends StatefulWidget {
  const DatingIntentionScreen({super.key});

  @override
  State<DatingIntentionScreen> createState() => _DatingIntentionScreenState();
}

class _DatingIntentionScreenState extends State<DatingIntentionScreen> {
  // NEW: Add service, user, and loading state variables
  final _profileService = ProfileService();
  final _currentUser = Supabase.instance.client.auth.currentUser;
  bool _loading = false;

  String? _selected;
  bool _visibleOnProfile = true;
  bool _pressed = false;

  static const List<String> _options = [
    'Life partner',
    'Long-term relationship',
    'Long-term relationship, open to short',
    'Short-term relationship, open to long',
    'Short-term relationship',
    'Figuring out my dating goals',
    'Prefer not to say',
  ];

  // NEW: Method to save data to Supabase and then navigate
  Future<void> _saveIntentionAndContinue() async {
    if (_selected == null || _currentUser == null || _loading) return;

    setState(() => _loading = true);

    try {
      await _profileService.upsertProfile(
        userId: _currentUser!.id,
        datingIntention: _selected,
        datingIntentionVisible: _visibleOnProfile,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RelationshipTypeScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save intention: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selected != null;

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
                    const Icon(Icons.search,
                        size: 40, color: Color(0xFF1F1F1F)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "What's your dating intention?",
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
                ..._options.map((o) => _OptionTile(
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
                  _saveIntentionAndContinue();
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
                  // MODIFIED: Show loading indicator when saving
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
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile(
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
