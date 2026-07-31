import 'package:flutter/material.dart';
import 'package:rizzexai/theme/app_typography.dart';

/// Top-right skip control for optional onboarding steps.
class OnboardingSkipButton extends StatelessWidget {
  final VoidCallback onSkip;
  final bool enabled;

  const OnboardingSkipButton({
    super.key,
    required this.onSkip,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: TextButton(
        onPressed: enabled ? onSkip : null,
        child: Text(
          'Skip',
          style: AppFonts.geist(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: enabled ? const Color(0xFF6B6B6B) : const Color(0xFFBDBDBD),
          ),
        ),
      ),
    );
  }
}

/// Wraps onboarding content with an optional skip button in the top-right.
class OnboardingSkipLayout extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSkip;
  final bool skipEnabled;

  const OnboardingSkipLayout({
    super.key,
    required this.child,
    this.onSkip,
    this.skipEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (onSkip == null) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          right: 8,
          child: OnboardingSkipButton(
            onSkip: onSkip!,
            enabled: skipEnabled,
          ),
        ),
      ],
    );
  }
}
