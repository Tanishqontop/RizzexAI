import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // NEW: Import Supabase
import '../services/profile_service.dart'; // NEW: Import ProfileService
import 'ethnicity_screen.dart';

class HeightScreen extends StatefulWidget {
  const HeightScreen({super.key});

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  // NEW: Add service, user, and loading state variables
  final _profileService = ProfileService();
  final _currentUser = Supabase.instance.client.auth.currentUser;
  bool _loading = false;

  bool _useFeet = true;
  double _heightCm = 165; // default
  bool _pressed = false;

  String _formatHeight() {
    if (_useFeet) {
      final totalInches = (_heightCm / 2.54).round();
      final feet = totalInches ~/ 12;
      final inches = totalInches % 12;
      return "$feet' $inches\"";
    }
    return '${_heightCm.round()} cm';
  }

  // NEW: Method to save data to Supabase and then navigate
  Future<void> _saveHeightAndContinue() async {
    if (_currentUser == null || _loading) return;

    setState(() => _loading = true);

    try {
      await _profileService.upsertProfile(
        userId: _currentUser!.id,
        heightCm: _heightCm.round(), // Save the height as an integer
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EthnicityScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save height: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bool hasSelection = true; // Button is always active for this screen

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
                    const Icon(Icons.straighten,
                        size: 40, color: Color(0xFF1F1F1F)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'How tall are you?',
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
                const SizedBox(height: 36),
                Center(
                  child: Text(
                    _formatHeight(),
                    style: AppFonts.display(
                        fontSize: 44, color: const Color(0xFF1F1F1F)),
                  ),
                ),
                const SizedBox(height: 24),
                Slider(
                  min: 120,
                  max: 210,
                  value: _heightCm,
                  activeColor: const Color(0xFF1F1F1F),
                  onChanged: (v) => setState(() => _heightCm = v),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDF2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _UnitChip(
                            label: 'FT',
                            active: _useFeet,
                            onTap: () => setState(() => _useFeet = true)),
                        _UnitChip(
                            label: 'CM',
                            active: !_useFeet,
                            onTap: () => setState(() => _useFeet = false)),
                      ],
                    ),
                  ),
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
                  _saveHeightAndContinue();
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
                  // MODIFIED: Show a loading indicator
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

class _UnitChip extends StatelessWidget {
  const _UnitChip(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppFonts.geist(
            color: const Color(0xFF1F1F1F),
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
