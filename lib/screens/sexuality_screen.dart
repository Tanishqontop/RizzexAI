import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'like_to_date_screen.dart';

class SexualityScreen extends StatefulWidget {
  const SexualityScreen({super.key});

  @override
  State<SexualityScreen> createState() => _SexualityScreenState();
}

class _SexualityScreenState extends State<SexualityScreen> {
  String? _selected;
  bool _visibleOnProfile = true;
  bool _isNextPressed = false;

  static const List<String> _options = [
    'Prefer not to say',
    'Straight',
    'Gay',
    'Lesbian',
    'Bisexual',
    'Allosexual',
    'Androsexual',
    'Asexual',
    'Autosexual',
    'Bicurious',
  ];

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
                    const Icon(Icons.groups_2_outlined, size: 40, color: Color(0xFF1F1F1F)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "What's your sexuality?",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 34,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                ..._options.map((o) => _SexualityTile(
                      label: o,
                      selected: _selected == o,
                      onTap: () => setState(() => _selected = o),
                    )),
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
                    MaterialPageRoute(builder: (_) => const LikeToDateScreen()),
                  );
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: hasSelection 
                        ? (_isNextPressed ? const Color(0xFF5A3BB1) : const Color(0xFF6B46C1))
                        : (_isNextPressed ? const Color(0xFFF0EDF2) : const Color(0xFFEDEAF1)),
                    shape: BoxShape.circle,
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
                    color: hasSelection ? Colors.white : const Color(0xFF1F1F1F)
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

class _SexualityTile extends StatelessWidget {
  const _SexualityTile({required this.label, required this.selected, required this.onTap});

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
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF1F1F1F)))),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD6D3D6)),
                color: selected ? const Color(0xFF6B46C1) : Colors.transparent,
              ),
              child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            )
          ],
        ),
      ),
    );
  }
}


