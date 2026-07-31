import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rizzexai/theme/app_typography.dart';
import '../models/user.dart';
import '../utils/profile_share.dart';

class FeedProfileView extends StatelessWidget {
  final User user;
  final User? currentUser;
  final ScrollController? scrollController;
  final VoidCallback? onCompliment;
  final VoidCallback? onSuperLike;

  const FeedProfileView({
    super.key,
    required this.user,
    this.currentUser,
    this.scrollController,
    this.onCompliment,
    this.onSuperLike,
  });

  bool get _isNewHere =>
      DateTime.now().difference(user.createdAt).inDays <= 7;

  List<String> get _photos => user.allPhotos;

  String get _nameAge {
    if (user.age != null) {
      return '${user.displayName}, ${user.age}';
    }
    return user.displayName;
  }

  List<String> _talkTopics() {
    final topics = <String>[];
    void add(String? value) {
      if (value == null) return;
      final trimmed = value.trim();
      if (trimmed.isEmpty || topics.contains(trimmed)) return;
      topics.add(trimmed);
    }

    add(user.lookingFor);
    add(user.religiousBelief);
    add(user.politicalBelief);
    if (user.ethnicity != null) {
      for (final item in user.ethnicity!) {
        add(item);
      }
    }
    return topics.take(4).toList();
  }

  List<({IconData icon, String label})> _aboutMeChips() {
    final chips = <({IconData icon, String label})>[];

    void add(IconData icon, String? value) {
      if (value == null) return;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      chips.add((icon: icon, label: trimmed));
    }

    if (user.heightFeet != null) {
      if (user.heightInches != null) {
        final totalInches = user.heightFeet! * 12 + user.heightInches!;
        final cm = (totalInches * 2.54).round();
        add(Icons.straighten, '$cm cm');
      } else {
        add(Icons.straighten, user.height);
      }
    }

    add(Icons.school_outlined, user.educationLevel);
    add(Icons.wine_bar_outlined, user.drinking);
    add(Icons.smoking_rooms_outlined, user.smokingTobacco);
    add(Icons.person_outline, user.gender);
    add(Icons.child_care_outlined, user.wantsChildren);
    add(Icons.baby_changing_station_outlined, user.hasChildren);
    add(Icons.star_outline, user.zodiacSign);
    add(Icons.work_outline, user.jobTitle);
    add(Icons.emoji_emotions_outlined, user.religiousBelief);
    add(Icons.wc_outlined, user.sexuality);

    return chips;
  }

  List<String> _interestTags() {
    final tags = <String>[];
    void add(String? value, [String emoji = '']) {
      if (value == null) return;
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      tags.add(emoji.isEmpty ? trimmed : '$emoji $trimmed');
    }

    add(user.lookingFor, '🔍');
    add(user.politicalBelief, '🗳️');
    add(user.religiousBelief, '🙂');
    add(user.drinking, '🍷');
    add(user.zodiacSign, '✨');
    return tags.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final talkTopics = _talkTopics();
    final aboutMe = _aboutMeChips();
    final interests = _interestTags();
    final extraPhotos = _photos.length > 1 ? _photos.sublist(1) : <String>[];

    return Container(
      color: const Color(0xFFF3F3F3),
      child: Stack(
        children: [
          ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              talkTopics.isNotEmpty ? 152 : 120,
            ),
            children: [
              _HeroSection(
                photoUrl: _photos.isNotEmpty ? _photos.first : null,
                nameAge: _nameAge,
                school: user.schoolName,
                isNewHere: _isNewHere,
                talkTopics: talkTopics,
                onCompliment: onCompliment,
              ),
              if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'My bio',
                  footer: _NoteFooter(onTap: onCompliment),
                  child: Text(
                    user.bio!.trim(),
                    style: AppFonts.geist(
                      fontSize: 16,
                      height: 1.45,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
          if (aboutMe.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'About me',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: aboutMe
                    .map((c) => _GreyChip(label: c.label, icon: c.icon))
                    .toList(),
              ),
            ),
          ],
          if (user.lookingFor != null && user.lookingFor!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: "I'm looking for",
              child: _GreyChip(
                label: user.lookingFor!.trim(),
                icon: Icons.search,
              ),
            ),
          ],
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'My interests',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests.map((t) => _GreyChip(label: t)).toList(),
              ),
            ),
          ],
          for (var i = 0; i < extraPhotos.length; i++) ...[
            const SizedBox(height: 12),
            _PhotoCard(imageUrl: extraPhotos[i]),
            if (i == 0 && user.workCompany != null && user.workCompany!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _SectionCard(
                title: 'My work',
                footer: _NoteFooter(onTap: onCompliment),
                child: Text(
                  '${user.jobTitle != null && user.jobTitle!.trim().isNotEmpty ? '${user.jobTitle!.trim()} at ' : ''}${user.workCompany!.trim()}',
                  style: AppFonts.geist(
                    fontSize: 16,
                    height: 1.45,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ],
          if (user.locationCity != null || user.locationState != null) ...[
            const SizedBox(height: 12),
            _LocationCard(locationLabel: user.location),
          ],
          const SizedBox(height: 24),
            ],
          ),
          Positioned(
            top: 20,
            right: 28,
            child: _ShareOverlayButton(
              onPressed: (origin) => shareUserProfileWithFeedback(
                context,
                user,
                sharePositionOrigin: origin,
              ),
            ),
          ),
          if (onSuperLike != null)
            Positioned(
              right: 12,
              bottom: 88,
              child: _CircleButton(
                color: FeedProfileActions.yellow,
                icon: Icons.star,
                iconColor: Colors.black,
                size: 56,
                onTap: onSuperLike,
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final String? photoUrl;
  final String nameAge;
  final String? school;
  final bool isNewHere;
  final List<String> talkTopics;
  final VoidCallback? onCompliment;

  const _HeroSection({
    required this.photoUrl,
    required this.nameAge,
    required this.school,
    required this.isNewHere,
    required this.talkTopics,
    this.onCompliment,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            _HeroPhoto(
              photoUrl: photoUrl,
              nameAge: nameAge,
              school: school,
              isNewHere: isNewHere,
            ),
            if (talkTopics.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: -56,
                child: _SectionCard(
                  title: 'Things we can talk about',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: talkTopics
                        .map((t) => _GreyChip(label: t, icon: Icons.search))
                        .toList(),
                  ),
                ),
              ),
            if (onCompliment != null)
              Positioned(
                left: 16,
                bottom: talkTopics.isNotEmpty ? 72 : 24,
                child: _CircleButton(
                  color: FeedProfileActions.yellow,
                  icon: Icons.mode_comment_outlined,
                  iconColor: Colors.black,
                  size: 52,
                  onTap: onCompliment,
                ),
              ),
          ],
        ),
        if (talkTopics.isNotEmpty) const SizedBox(height: 72),
      ],
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  final String? photoUrl;
  final String nameAge;
  final String? school;
  final bool isNewHere;

  const _HeroPhoto({
    required this.photoUrl,
    required this.nameAge,
    required this.school,
    required this.isNewHere,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 440,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photoUrl != null)
              CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: const Color(0xFFE0E0E0)),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            else
              _placeholder(),
            Positioned(
              left: 16,
              top: 16,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isNewHere) const _Badge(label: 'New here', dark: false),
                  const _Badge(
                    label: 'Photo verified',
                    dark: true,
                    icon: Icons.verified,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameAge,
                      style: AppFonts.geist(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (school != null && school!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              school!.trim(),
                              style: AppFonts.geist(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE0E0E0),
      child: const Center(
        child: Icon(Icons.person, size: 80, color: Color(0xFFB0B0B0)),
      ),
    );
  }
}

class _ShareOverlayButton extends StatelessWidget {
  final Future<void> Function(Rect origin) onPressed;

  const _ShareOverlayButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          await onPressed(shareButtonOrigin(context));
        },
        borderRadius: BorderRadius.circular(10),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.share_outlined, size: 20),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool dark;
  final IconData? icon;

  const _Badge({
    required this.label,
    required this.dark,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: dark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: dark ? Colors.white : Colors.black),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppFonts.geist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? footer;

  const _SectionCard({
    required this.title,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppFonts.geist(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          child,
          if (footer != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFECECEC)),
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _GreyChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _GreyChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFF333333)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppFonts.geist(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteFooter extends StatelessWidget {
  final VoidCallback? onTap;

  const _NoteFooter({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCCCCCC)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite_border, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            'Note',
            style: AppFonts.geist(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String imageUrl;

  const _PhotoCard({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: const Color(0xFFE0E0E0)),
          errorWidget: (_, __, ___) => Container(
            color: const Color(0xFFE0E0E0),
            child: const Icon(Icons.broken_image),
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String locationLabel;

  const _LocationCard({required this.locationLabel});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'My location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  locationLabel,
                  style: AppFonts.geist(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _GreyChip(
            label: 'Lives in $locationLabel',
            icon: Icons.home_outlined,
          ),
        ],
      ),
    );
  }
}

class FeedProfileActions extends StatelessWidget {
  final VoidCallback? onPass;
  final VoidCallback? onLike;

  const FeedProfileActions({
    super.key,
    this.onPass,
    this.onLike,
  });

  static const yellow = Color(0xFFFFC629);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _CircleButton(
            color: Colors.white,
            icon: Icons.close,
            iconColor: Colors.black54,
            size: 52,
            onTap: onPass,
            border: true,
          ),
          const SizedBox(width: 24),
          _CircleButton(
            color: const Color(0xFF6B46C1),
            icon: Icons.favorite,
            iconColor: Colors.white,
            size: 52,
            onTap: onLike,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final double size;
  final VoidCallback? onTap;
  final bool border;

  const _CircleButton({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.size,
    this.onTap,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: border ? Border.all(color: const Color(0xFFE0E0E0)) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: size * 0.42),
        ),
      ),
    );
  }
}
