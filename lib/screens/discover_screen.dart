import 'package:rizzexai/theme/app_typography.dart';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/feed_service.dart';
import '../services/compliment_service.dart';
import '../services/super_like_service.dart';
import '../utils/discover_sections.dart';
import '../widgets/discover_profile_card.dart';
import '../widgets/discover_profile_modal.dart';
import '../widgets/match_dialog.dart';
import '../widgets/compliment_sheet.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  DiscoverScreenState createState() => DiscoverScreenState();
}

class DiscoverScreenState extends State<DiscoverScreen> {

  final FeedService _feedService = FeedService();
  final ComplimentService _complimentService = ComplimentService();
  final SuperLikeService _superLikeService = SuperLikeService();

  List<User> _users = [];
  User? _currentUser;
  bool _isLoading = true;
  String? _error;
  int _remainingCompliments = ComplimentService.dailyLimit;
  int _remainingSuperLikes = SuperLikeService.weeklyLimit;

  static const _cardHeight = 430.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Called when the Discover tab becomes active.
  void refresh() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _feedService.getDiscoverProfiles(limit: 36),
        _feedService.getCurrentUserProfile(),
        _complimentService.getRemainingComplimentsToday(),
        _superLikeService.getRemainingSuperLikesThisWeek(),
      ]);

      if (mounted) {
        setState(() {
          _users = results[0] as List<User>;
          _currentUser = results[1] as User?;
          _remainingCompliments = results[2] as int;
          _remainingSuperLikes = results[3] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Discover load error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _recordSwipe(
    User user, {
    required bool isLike,
    bool superLike = false,
  }) async {
    try {
      if (superLike && _remainingSuperLikes <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have used all ${SuperLikeService.weeklyLimit} Super Likes for this week',
              ),
            ),
          );
        }
        return;
      }

      final match = await _feedService.recordSwipe(
        targetUserId: user.id,
        isLike: isLike,
        superLike: superLike ? 'true' : null,
      );

      if (!mounted) return;

      if (superLike) {
        final remaining =
            await _superLikeService.getRemainingSuperLikesThisWeek();
        setState(() => _remainingSuperLikes = remaining);
      }

      if (isLike) {
        setState(() => _users.removeWhere((u) => u.id == user.id));
      }

      if (match != null) {
        await showMatchDialog(context, match);
      } else if (isLike) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              superLike
                  ? 'Super liked ${user.displayName}!'
                  : 'You liked ${user.displayName}',
            ),
            backgroundColor:
                superLike ? const Color(0xFFFFC629) : const Color(0xFF6B46C1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update profile: $e')),
        );
      }
    }
  }

  Future<void> _sendCompliment(User user) async {
    await showSendComplimentSheet(
      context: context,
      recipient: user,
      remainingCompliments: _remainingCompliments,
      onSend: (message) async {
        try {
          await _complimentService.sendCompliment(
            recipientId: user.id,
            message: message,
          );
          final remaining =
              await _complimentService.getRemainingComplimentsToday();
          if (mounted) {
            setState(() => _remainingCompliments = remaining);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Compliment sent to ${user.displayName}!'),
                backgroundColor: const Color(0xFF6B46C1),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceFirst('Exception: ', '')),
              ),
            );
          }
        }
      },
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Discover',
          style: AppFonts.geist(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Browse people grouped by shared interests, dating goals, and '
          'communities. Tap a card for the full profile, or tap the heart to like.',
          style: AppFonts.geist(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _openProfile(User user) {
    showDiscoverProfileModal(
      context: context,
      user: user,
      currentUser: _currentUser,
      onLike: () => _recordSwipe(user, isLike: true),
      onPass: () => _recordSwipe(user, isLike: false),
      onCompliment: _remainingCompliments > 0
          ? () => _sendCompliment(user)
          : null,
      onSuperLike: _remainingSuperLikes > 0
          ? () => _recordSwipe(user, isLike: true, superLike: true)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'You have used all ${SuperLikeService.weeklyLimit} Super Likes for this week',
                  ),
                ),
              );
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.72;
    final sections = buildDiscoverSections(
      allUsers: _users,
      currentUser: _currentUser,
    ).where((section) => section.users.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFF6B46C1),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Discover',
                              style: AppFonts.geist(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _showHelp,
                            icon: const Icon(Icons.help_outline),
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect over common ground with people who match your '
                        'vibe, refreshed every day.',
                        style: AppFonts.geist(
                          fontSize: 15,
                          height: 1.45,
                          color: const Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Could not load profiles',
                            style: AppFonts.geist(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _loadData,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6B46C1),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (_users.isEmpty || sections.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No new profiles right now. Check back tomorrow!',
                        textAlign: TextAlign.center,
                        style: AppFonts.geist(
                          fontSize: 16,
                          color: const Color(0xFF6B6B6B),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final section = sections[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == sections.length - 1 ? 32 : 28,
                        ),
                        child: _DiscoverSection(
                          title: section.title,
                          cardWidth: cardWidth,
                          cardHeight: _cardHeight,
                          users: section.users,
                          highlightsBuilder: (user) =>
                              discoverHighlightsForSection(user, section.kind),
                          onOpenProfile: _openProfile,
                          onLike: (user) => _recordSwipe(user, isLike: true),
                        ),
                      );
                    },
                    childCount: sections.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverSection extends StatelessWidget {
  final String title;
  final double cardWidth;
  final double cardHeight;
  final List<User> users;
  final List<String> Function(User user) highlightsBuilder;
  final void Function(User user) onOpenProfile;
  final void Function(User user) onLike;

  const _DiscoverSection({
    required this.title,
    required this.cardWidth,
    required this.cardHeight,
    required this.users,
    required this.highlightsBuilder,
    required this.onOpenProfile,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            title,
            style: AppFonts.geist(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              letterSpacing: -0.2,
            ),
          ),
        ),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final user = users[index];
              return SizedBox(
                width: cardWidth,
                child: DiscoverProfileCard(
                  user: user,
                  highlights: highlightsBuilder(user),
                  onLike: () => onLike(user),
                  onTap: () => onOpenProfile(user),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
