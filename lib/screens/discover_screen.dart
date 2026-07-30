import 'package:rizzexai/theme/app_typography.dart';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/feed_service.dart';
import '../widgets/discover_profile_card.dart';
import '../widgets/match_dialog.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final FeedService _feedService = FeedService();
  final ScrollController _scrollController = ScrollController();

  List<User> _users = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || _isLoading) return;
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProfiles();
    }
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _feedService.getPotentialMatches(limit: 20);
      if (mounted) {
        setState(() {
          _users = users;
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

  Future<void> _loadMoreProfiles() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final more = await _feedService.loadMoreProfiles(_users.length);
      if (mounted) {
        setState(() {
          _users.addAll(more);
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      developer.log('Discover load more error: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _likeUser(User user) async {
    try {
      final match = await _feedService.recordSwipe(
        targetUserId: user.id,
        isLike: true,
      );

      if (mounted) {
        setState(() => _users.removeWhere((u) => u.id == user.id));

        if (match != null) {
          await showMatchDialog(context, match);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You liked ${user.displayName}'),
              backgroundColor: const Color(0xFF6B46C1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not like profile: $e')),
        );
      }
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discover', style: AppFonts.geist(fontWeight: FontWeight.w700)),
        content: Text(
          'Every day we surface people who share your interests and dating '
          'preferences. Tap a card to preview, or tap the heart to like.',
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

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.78;
    const cardHeight = 430.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfiles,
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD54F),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'See new people in 24 hours',
                          style: AppFonts.geist(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                      Text(
                        'Recommended for you',
                        style: AppFonts.geist(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                            onPressed: _loadProfiles,
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
              else if (_users.isEmpty)
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
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: cardHeight,
                    child: ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      itemCount: _users.length + (_isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        if (index >= _users.length) {
                          return SizedBox(
                            width: cardWidth,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final user = _users[index];
                        return SizedBox(
                          width: cardWidth,
                          child: DiscoverProfileCard(
                            user: user,
                            highlights: discoverHighlightsFor(user),
                            onLike: () => _likeUser(user),
                            onTap: () => _showProfilePreview(user),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Based on your profile and past matches',
                          style: AppFonts.geist(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfilePreview(User user) {
    final photos = user.allPhotos;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  if (photos.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Image.network(
                        photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE8E8E8),
                          child: const Icon(Icons.person, size: 80),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.age != null
                              ? '${user.displayName}, ${user.age}'
                              : user.displayName,
                          style: AppFonts.geist(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            user.bio!,
                            style: AppFonts.geist(
                              fontSize: 15,
                              height: 1.45,
                              color: const Color(0xFF4A4A4A),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _likeUser(user);
                            },
                            icon: const Icon(Icons.favorite),
                            label: const Text('Like'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6B46C1),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
