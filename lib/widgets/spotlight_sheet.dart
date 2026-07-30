import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';

Future<void> showSpotlightSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) {
      return const _SpotlightSheetContent();
    },
  );
}

class _SpotlightSheetContent extends StatelessWidget {
  const _SpotlightSheetContent();

  static const _features = [
    _SpotlightFeature(
      icon: Icons.timer_outlined,
      title: 'Lasts 30 minutes',
      description: 'Your Spotlight stays active for half an hour.',
    ),
    _SpotlightFeature(
      icon: Icons.vertical_align_top,
      title: 'Top of swipe feeds',
      description:
          "Moves your profile near the top of other users' swipe feeds.",
    ),
    _SpotlightFeature(
      icon: Icons.hourglass_bottom_outlined,
      title: 'Countdown timer',
      description: 'See exactly how much Spotlight time you have left.',
    ),
    _SpotlightFeature(
      icon: Icons.shopping_bag_outlined,
      title: 'Buy individually',
      description: 'Purchase Spotlight on its own — no plan required.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spotlight',
                            style: AppFonts.geist(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stand out and get seen by more people.',
                            style: AppFonts.geist(
                              fontSize: 14,
                              color: const Color(0xFF6B6B6B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 24),
                      color: Colors.black,
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Feature plan',
                  style: AppFonts.geist(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9A9A9A),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                for (final feature in _features) ...[
                  _FeatureTile(feature: feature),
                  if (feature != _features.last) const SizedBox(height: 12),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Spotlight purchase coming soon'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Get Spotlight',
                      style: AppFonts.geist(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final _SpotlightFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(feature.icon, size: 22, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: AppFonts.geist(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: AppFonts.geist(
                    fontSize: 13,
                    color: const Color(0xFF6B6B6B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightFeature {
  final IconData icon;
  final String title;
  final String description;

  const _SpotlightFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
}
