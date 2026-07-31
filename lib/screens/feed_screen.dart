import 'package:flutter/material.dart';
import 'package:rizzexai/theme/app_typography.dart';
import '../models/user.dart';
import '../models/user_match.dart';
import '../widgets/love_loading_view.dart';
import '../services/feed_service.dart';
import '../widgets/swipeable_card_stack.dart';
import '../widgets/match_dialog.dart';
import '../widgets/compliment_sheet.dart';
import '../services/compliment_service.dart';
import '../services/super_like_service.dart';
import 'dart:developer' as developer;

class _FeedSwipeRecord {
  final User user;
  final SwipeDirection direction;
  final UserMatch? match;

  const _FeedSwipeRecord({
    required this.user,
    required this.direction,
    this.match,
  });
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FeedService _feedService = FeedService();
  final ComplimentService _complimentService = ComplimentService();
  final SuperLikeService _superLikeService = SuperLikeService();
  List<User> _users = [];
  User? _currentUser;
  bool _isLoading = true;
  String? _error;
  int _remainingCompliments = ComplimentService.dailyLimit;
  int _remainingSuperLikes = SuperLikeService.weeklyLimit;
  int _swipedCount = 0;
  int _currentIndex = 0;
  final List<_FeedSwipeRecord> _swipeHistory = [];
  bool _isRewinding = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUsers();
    _loadComplimentQuota();
    _loadSuperLikeQuota();
  }

  Future<void> _loadSuperLikeQuota() async {
    try {
      final remaining = await _superLikeService.getRemainingSuperLikesThisWeek();
      if (mounted) {
        setState(() => _remainingSuperLikes = remaining);
      }
    } catch (e) {
      developer.log('Error loading super like quota: $e');
    }
  }

  Future<void> _loadComplimentQuota() async {
    try {
      final remaining = await _complimentService.getRemainingComplimentsToday();
      if (mounted) {
        setState(() => _remainingCompliments = remaining);
      }
    } catch (e) {
      developer.log('Error loading compliment quota: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final profile = await _feedService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = profile;
        });
      }
    } catch (e) {
      developer.log('Error loading current user profile: $e');
    }
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final users = await _feedService.getPotentialMatches(limit: 20);
      
      if (mounted) {
        setState(() {
          _users = users.cast<User>();
          _isLoading = false;
          _swipedCount = 0;
          _currentIndex = 0;
          _swipeHistory.clear();
        });
      }
    } catch (e) {
      developer.log('Error loading users: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshFeed() async {
    try {
      setState(() => _error = null);

      final users = await _feedService.refreshFeed();
      
      if (mounted) {
        setState(() {
          _users = users.cast<User>();
          _swipedCount = 0;
          _currentIndex = 0;
          _swipeHistory.clear();
        });
      }
    } catch (e) {
      developer.log('Error refreshing feed: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadMoreUsers() async {
    try {
      final moreUsers = await _feedService.loadMoreProfiles(_users.length);
      
      if (mounted) {
        setState(() {
          _users.addAll(moreUsers.cast<User>());
        });
      }
    } catch (e) {
      developer.log('Error loading more users: $e');
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
          await _loadComplimentQuota();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Compliment sent to ${user.displayName}!',
                ),
                backgroundColor: const Color(0xFF6B46C1),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
            );
          }
        }
      },
    );
  }

  Future<bool> _onSwipe(User user, SwipeDirection direction) async {
    try {
      final isSuperLike = direction == SwipeDirection.up;
      if (isSuperLike && _remainingSuperLikes <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have used all ${SuperLikeService.weeklyLimit} Super Likes for this week',
              ),
            ),
          );
        }
        return false;
      }

      final match = await _feedService.recordSwipe(
        targetUserId: user.id,
        isLike: direction == SwipeDirection.right || isSuperLike,
        superLike: isSuperLike ? 'true' : null,
      );

      if (isSuperLike) {
        await _loadSuperLikeQuota();
      }

      if (match != null && mounted) {
        await showMatchDialog(context, match);
      } else if (mounted && isSuperLike) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Super Liked ${user.displayName}!'),
            backgroundColor: const Color(0xFFFFC629),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _swipedCount++;
          _currentIndex++;
          _swipeHistory.add(
            _FeedSwipeRecord(
              user: user,
              direction: direction,
              match: match,
            ),
          );
        });
      }

      if (_users.length - _currentIndex < 3) {
        _loadMoreUsers();
      }

      return true;
    } catch (e) {
      developer.log('Error recording swipe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _rewindLastSwipe() async {
    if (_isRewinding || _swipeHistory.isEmpty) {
      if (mounted && _swipeHistory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to rewind yet')),
        );
      }
      return;
    }

    setState(() => _isRewinding = true);

    final record = _swipeHistory.removeLast();

    try {
      await _feedService.rewindSwipe(
        targetUserId: record.user.id,
        matchIdToRemove: record.match?.id,
      );

      if (record.direction == SwipeDirection.up) {
        await _loadSuperLikeQuota();
      }

      if (!mounted) return;

      setState(() {
        _currentIndex = (_currentIndex - 1).clamp(0, _users.length);
        _swipedCount = (_swipedCount - 1).clamp(0, _users.length);
        _isRewinding = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rewound ${record.user.displayName}'),
          backgroundColor: const Color(0xFF6B46C1),
        ),
      );
    } catch (e) {
      developer.log('Error rewinding swipe: $e');
      _swipeHistory.add(record);
      if (mounted) {
        setState(() => _isRewinding = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  Text(
                    'Rizzex',
                    style: AppFonts.geist(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _swipeHistory.isEmpty || _isRewinding
                        ? null
                        : _rewindLastSwipe,
                    icon: _isRewinding
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.replay,
                            color: _swipeHistory.isEmpty
                                ? Colors.black26
                                : Colors.black,
                          ),
                    tooltip: 'Rewind',
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoveLoadingView();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadUsers,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'No profiles found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Check back later for new matches!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _refreshFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return SwipeableCardStack(
      users: _users,
      currentIndex: _currentIndex,
      currentUser: _currentUser,
      onSwipeAsync: _onSwipe,
      onCompliment: _sendCompliment,
      remainingCompliments: _remainingCompliments,
      remainingSuperLikes: _remainingSuperLikes,
      onEmpty: _loadMoreUsers,
    );
  }
}
