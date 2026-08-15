import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../widgets/onboarding_celebration_confetti.dart';
import 'auth_wrapper.dart';

class FinalOnboardingScreen extends StatefulWidget {
  const FinalOnboardingScreen({super.key, required this.uploadedCount});

  final int uploadedCount;

  @override
  State<FinalOnboardingScreen> createState() => _FinalOnboardingScreenState();
}

class _FinalOnboardingScreenState extends State<FinalOnboardingScreen>
    with TickerProviderStateMixin {
  bool _isFinishing = false;
  int _burstTrigger = 0;
  bool _rainActive = false;

  late AnimationController _celebrationController;
  late Animation<double> _popperIntro;
  late Animation<double> _contentReveal;
  late Animation<double> _popperTravel;
  late Animation<double> _rainIntensity;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _popperIntro = CurvedAnimation(
      parent: _celebrationController,
      curve: const Interval(0.0, 0.28, curve: Curves.elasticOut),
    );

    _contentReveal = CurvedAnimation(
      parent: _celebrationController,
      curve: const Interval(0.35, 0.72, curve: Curves.easeOutCubic),
    );

    _popperTravel = CurvedAnimation(
      parent: _celebrationController,
      curve: const Interval(0.30, 0.68, curve: Curves.easeInOutCubic),
    );

    _rainIntensity = CurvedAnimation(
      parent: _celebrationController,
      curve: const Interval(0.38, 0.78, curve: Curves.easeIn),
    );

    _celebrationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _rainActive = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _celebrationController.forward(from: 0);
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _burstTrigger = 1);
      });
    });
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;

    setState(() => _isFinishing = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await ProfileService().upsertProfile(
          userId: userId,
          onboardingCompleted: true,
        );
      }

      if (!mounted) return;
      navigateToAuthRoot(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to finish onboarding: $e')),
        );
        setState(() => _isFinishing = false);
      }
    }
  }

  double get _rainStrength {
    if (_rainActive) return 0.65;
    return _rainIntensity.value * 0.65;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeVertical = MediaQuery.paddingOf(context).vertical;
    final availableHeight = screenHeight - safeVertical;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, _) {
                final reveal = _contentReveal.value;
                final popperY = Tween<double>(begin: 0.18, end: 0.04)
                    .transform(_popperTravel.value);
                final popperScale = (0.35 + _popperIntro.value * 0.65) *
                    (1 - _popperTravel.value * 0.1);
                final topSpacing =
                    (availableHeight * popperY).clamp(16.0, 180.0);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    OnboardingCelebrationConfetti(
                      burstTrigger: _burstTrigger,
                      burstOriginFraction: 0.22,
                      rainIntensity: _rainStrength,
                    ),
                    SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          children: [
                            SizedBox(height: topSpacing),
                            Transform.scale(
                              scale: popperScale,
                              child: const Text(
                                '🎉',
                                style: TextStyle(fontSize: 88, height: 1),
                              ),
                            ),
                            SizedBox(height: 12 * reveal.clamp(0.0, 1.0)),
                            Opacity(
                              opacity: reveal,
                              child: Transform.translate(
                                offset: Offset(0, 28 * (1 - reveal)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28),
                                  child: Column(
                                    children: [
                                      Text(
                                        "Congratulations,\nYou're On Board!",
                                        textAlign: TextAlign.center,
                                        style: AppFonts.display(
                                          fontSize: 26,
                                          height: 1.15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Your profile is ready. Start discovering people '
                                        'and making real connections.',
                                        textAlign: TextAlign.center,
                                        style: AppFonts.geist(
                                          fontSize: 16,
                                          height: 1.45,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white
                                              .withValues(alpha: 0.88),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: availableHeight < 640 ? 24 : 40),
                            Opacity(
                              opacity: reveal,
                              child: Transform.translate(
                                offset: Offset(0, 36 * (1 - reveal)),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 0, 24, 16),
                                  child: _RainbowGlowButton(
                                    onPressed: _isFinishing || reveal < 0.85
                                        ? null
                                        : _finishOnboarding,
                                    child: _isFinishing
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black,
                                            ),
                                          )
                                        : Text(
                                            'Get Started',
                                            style: AppFonts.geist(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _RainbowGlowButton extends StatelessWidget {
  const _RainbowGlowButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  static const _gradientColors = [
    Color(0xFFFF0080),
    Color(0xFFFF8C00),
    Color(0xFFFFEB3B),
    Color(0xFF00E676),
    Color(0xFF00B0FF),
    Color(0xFF7C4DFF),
    Color(0xFFFF0080),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(colors: _gradientColors),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0080).withValues(alpha: 0.35),
            blurRadius: 18,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFF00B0FF).withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(29),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(29),
          child: SizedBox(
            height: 56,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
