import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dating_intention_screen.dart';

class LikeToDateScreen extends StatefulWidget {
  const LikeToDateScreen({super.key});

  @override
  State<LikeToDateScreen> createState() => _LikeToDateScreenState();
}

class _LikeToDateScreenState extends State<LikeToDateScreen> {
  final Set<String> _selected = <String>{};
  static const List<String> _options = [
    'Men', 'Women', 'Non-binary people', 'Everyone'
  ];
  bool _pressed = false;

  void _toggle(String value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
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
                    const Icon(Icons.favorite_border, size: 40, color: Color(0xFF1F1F1F)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Who would you like to date?',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 34,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Select all the people you're open to meeting",
                            style: GoogleFonts.inter(color: const Color(0xFF9A979A)),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                ..._options.map((o) => _LikeTile(
                      label: o,
                      selected: _selected.contains(o),
                      onTap: () => _toggle(o),
                    )),
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
                    MaterialPageRoute(builder: (_) => const DatingIntentionScreen()),
                  );
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: hasSelection 
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
                    color: hasSelection ? Colors.white : const Color(0xFF1F1F1F)
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

class _LikeTile extends StatelessWidget {
  const _LikeTile({required this.label, required this.selected, required this.onTap});

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
              child: Text(label, style: GoogleFonts.inter(fontSize: 18, color: const Color(0xFF1F1F1F))),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD6D3D6)),
                borderRadius: BorderRadius.circular(4),
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


