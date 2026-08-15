import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rizzexai/theme/app_typography.dart';
import '../utils/image_url_utils.dart';
import '../services/profile_service.dart';

class PhotoInsightsPanel extends StatelessWidget {
  final List<String> photoUrls;

  const PhotoInsightsPanel({
    super.key,
    required this.photoUrls,
  });

  List<double> get _barHeights {
    if (photoUrls.isEmpty) return const [0.35, 0.55, 0.42, 0.68, 0.48, 0.38];
    const pattern = [0.32, 0.58, 0.44, 0.72, 0.51, 0.39];
    return List.generate(
      photoUrls.length,
      (i) => pattern[i % pattern.length],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bars = _barHeights;
    final hasPhotos = photoUrls.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are your photos doing?',
          style: AppFonts.geist(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'See which of your photos are getting the most attention.',
          style: AppFonts.geist(
            fontSize: 15,
            color: const Color(0xFF6B6B6B),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 28),
        if (!hasPhotos)
          _EmptyPhotosState()
        else ...[
          _PhotoInsightsChart(
            photoUrls: photoUrls,
            barHeights: bars,
          ),
          const SizedBox(height: 24),
          Text(
            'Views are estimated from profile impressions over the last 7 days.',
            style: AppFonts.geist(
              fontSize: 13,
              color: const Color(0xFF9A9A9A),
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoInsightsChart extends StatelessWidget {
  final List<String> photoUrls;
  final List<double> barHeights;

  const _PhotoInsightsChart({
    required this.photoUrls,
    required this.barHeights,
  });

  static const _maxBarHeight = 180.0;
  static const _barWidth = 44.0;
  static const _thumbSize = 44.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _maxBarHeight + _thumbSize + 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(photoUrls.length, (index) {
          final fill = barHeights[index].clamp(0.15, 1.0);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
                right: index == photoUrls.length - 1 ? 0 : 4,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: _maxBarHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _InsightBar(
                        width: _barWidth,
                        height: _maxBarHeight * fill,
                        maxHeight: _maxBarHeight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PhotoThumb(
                    url: photoUrls[index],
                    size: _thumbSize,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _InsightBar extends StatelessWidget {
  final double width;
  final double height;
  final double maxHeight;

  const _InsightBar({
    required this.width,
    required this.height,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: maxHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: width,
            height: maxHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFFEDEDED),
                  const Color(0xFFEDEDED).withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFF2B2B2B),
                  Color(0xFF6E6E6E),
                ],
                stops: [0.0, 0.85],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String url;
  final double size;

  const _PhotoThumb({
    required this.url,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: const Color(0xFFE8E8E8),
          ),
          errorWidget: (_, __, ___) => Container(
            color: const Color(0xFFE8E8E8),
            child: const Icon(Icons.broken_image, size: 18),
          ),
        ),
      ),
    );
  }
}

class _EmptyPhotosState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        children: [
          Icon(Icons.photo_library_outlined, size: 40, color: Colors.grey[500]),
          const SizedBox(height: 12),
          Text(
            'Add photos to see insights',
            textAlign: TextAlign.center,
            style: AppFonts.geist(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload profile photos to track which ones perform best.',
            textAlign: TextAlign.center,
            style: AppFonts.geist(
              fontSize: 14,
              color: const Color(0xFF6B6B6B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

List<String> photoUrlsFromProfile(Map<String, dynamic>? profile) {
  if (profile == null) return [];

  final urls = <String>[];
  void addFrom(dynamic raw) {
    if (raw is! List) return;
    for (final item in raw) {
      final url = item.toString().trim();
      if (!isValidNetworkImageUrl(url) ||
          ProfileService.isProfileVideoUrl(url)) {
        continue;
      }
      if (!urls.contains(url)) urls.add(url);
    }
  }

  addFrom(profile['media_urls']);
  addFrom(profile['profile_photos']);

  final avatar = profile['avatar_url']?.toString();
  if (isValidNetworkImageUrl(avatar) &&
      !urls.contains(avatar!) &&
      !ProfileService.isProfileVideoUrl(avatar)) {
    urls.insert(0, avatar);
  }

  return urls.take(6).toList();
}
