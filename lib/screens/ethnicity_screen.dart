import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // NEW: Import Supabase
import '../services/profile_service.dart'; // NEW: Import ProfileService
import 'children_screen.dart';

class EthnicityScreen extends StatefulWidget {
  const EthnicityScreen({super.key});

  @override
  State<EthnicityScreen> createState() => _EthnicityScreenState();
}

class _EthnicityScreenState extends State<EthnicityScreen> {
  // NEW: Add service, user, and loading state variables
  final _profileService = ProfileService();
  final _currentUser = Supabase.instance.client.auth.currentUser;
  bool _loading = false;

  final Set<String> _selected = <String>{};
  bool _visibleOnProfile = true;
  bool _pressed = false;

  static const List<String> _options = [
    'Black/African Descent',
    'East Asian',
    'Hispanic/Latino',
    'Middle Eastern',
    'Native American',
    'Pacific Islander',
    'South Asian',
    'Southeast Asian',
    'White/Caucasian',
    'Other',
  ];

  void _toggle(String o) {
    setState(() {
      if (_selected.contains(o)) {
        _selected.remove(o);
      } else {
        _selected.add(o);
      }
    });
  }

  // NEW: Method to save data to Supabase and then navigate
  Future<void> _saveEthnicityAndContinue() async {
    if (_selected.isEmpty || _currentUser == null || _loading) return;

    setState(() => _loading = true);

    try {
      await _profileService.upsertProfile(
        userId: _currentUser!.id,
        ethnicity: _selected.toList(), // Convert Set to List
        ethnicityVisible: _visibleOnProfile,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChildrenScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save ethnicity: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selected.isNotEmpty;

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
                    const Icon(Icons.public,
                        size: 40, color: Color(0xFF1F1F1F)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "What's your ethnicity?",
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
                ..._options.map((o) => _EthTile(
                      label: o,
                      selected: _selected.contains(o),
                      onTap: () => _toggle(o),
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
                        style: GoogleFonts.inter(fontSize: 16)),
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
                  _saveEthnicityAndContinue();
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
    );
  }
}

class _EthTile extends StatelessWidget {
  const _EthTile(
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
                    style: GoogleFonts.inter(
                        fontSize: 18, color: const Color(0xFF1F1F1F)))),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD6D3D6)),
                borderRadius: BorderRadius.circular(4),
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
