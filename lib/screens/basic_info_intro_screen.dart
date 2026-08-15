import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';
import '../widgets/onboarding_skip_button.dart';
import 'name_entry_screen.dart';

class BasicInfoIntroScreen extends StatelessWidget {
  const BasicInfoIntroScreen({super.key});

  void _continue(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NameEntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: OnboardingSkipLayout(
          onSkip: () => _continue(context),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 560;

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24, 8, 24, compact ? 12 : 16),
                      child: Column(
                        children: [
                          SizedBox(height: compact ? 8 : 24),
                          Text(
                            "You're one of a kind.\nYour profile should be, too.",
                            textAlign: TextAlign.center,
                            style: AppFonts.display(
                              fontSize: compact ? 28 : 36,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                          SizedBox(height: compact ? 16 : 28),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: compact ? 132 : 220,
                              maxWidth: double.infinity,
                            ),
                            child: AspectRatio(
                              aspectRatio: 3 / 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1ECF5),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 48,
                                    color: Color(0xFF6B46C1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _continue(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B46C1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Enter basic info',
                          style: AppFonts.geist(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
