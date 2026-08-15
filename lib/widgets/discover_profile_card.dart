import 'package:rizzexai/theme/app_typography.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/image_url_utils.dart';

class DiscoverProfileCard extends StatelessWidget {
  final User user;
  final List<String> highlights;
  final VoidCallback? onLike;
  final VoidCallback? onTap;

  const DiscoverProfileCard({
    super.key,
    required this.user,
    required this.highlights,
    this.onLike,
    this.onTap,
  });

  String get _shortName {
    if (user.firstName != null && user.firstName!.isNotEmpty) {
      return user.firstName!;
    }
    final name = user.displayName.trim();
    if (name.isEmpty) return '?';
    return name.split(' ').first;
  }

  String get _nameAgeLine {
    final initial = _shortName.isNotEmpty ? _shortName[0].toUpperCase() : '?';
    if (user.age != null) {
      return '$initial, ${user.age}';
    }
    return initial;
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.allPhotos.isNotEmpty ? user.allPhotos.first : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isValidNetworkImageUrl(photoUrl))
                    CachedNetworkImage(
                      imageUrl: photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFFF0F0F0),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _photoPlaceholder(),
                    )
                  else
                    _photoPlaceholder(),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 48, 14, 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                      child: _HighlightRow(highlights: highlights),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            _nameAgeLine,
                            style: AppFonts.geist(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      onLike?.call();
                    },
                    icon: const Icon(Icons.favorite_border),
                    color: Colors.black,
                    iconSize: 26,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: const Color(0xFFE8E8E8),
      child: const Center(
        child: Icon(Icons.person, size: 64, color: Color(0xFFB0B0B0)),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final List<String> highlights;

  const _HighlightRow({required this.highlights});

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) return const SizedBox.shrink();

    final chips = <Widget>[
      _HighlightChip(label: highlights.first),
    ];

    if (highlights.length > 1) {
      chips.add(_HighlightChip(label: '+${highlights.length - 1}'));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }
}

class _HighlightChip extends StatelessWidget {
  final String label;

  const _HighlightChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppFonts.geist(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

