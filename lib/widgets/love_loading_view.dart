import 'package:flutter/material.dart';
import 'package:rizzexai/theme/app_typography.dart';

/// Minimal loading screen shown while auth resolves and the feed prepares.
class LoveLoadingView extends StatelessWidget {
  const LoveLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF6B46C1),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Love is loading...',
              style: AppFonts.geist(
                fontSize: 13,
                color: const Color(0xFF8A8A8A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
