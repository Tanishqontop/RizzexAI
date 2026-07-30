import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/feed_service.dart';
import '../widgets/swipeable_card_stack.dart';
import '../widgets/match_dialog.dart';
import '../widgets/compliment_sheet.dart';
import '../services/compliment_service.dart';
import 'dart:developer' as developer;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FeedService _feedService = FeedService();
  final ComplimentService _complimentService = ComplimentService();
  List<User> _users = [];
  User? _currentUser;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  int _remainingCompliments = ComplimentService.dailyLimit;
  int _swipedCount = 0;
  Key _feedStackKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUsers();
    _loadComplimentQuota();
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
          _feedStackKey = UniqueKey();
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
      setState(() {
        _isRefreshing = true;
        _error = null;
      });

      final users = await _feedService.refreshFeed();
      
      if (mounted) {
        setState(() {
          _users = users.cast<User>();
          _isRefreshing = false;
          _swipedCount = 0;
          _feedStackKey = UniqueKey();
        });
      }
    } catch (e) {
      developer.log('Error refreshing feed: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isRefreshing = false;
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

  void _onSwipe(User user, SwipeDirection direction) async {
    try {
      final match = await _feedService.recordSwipe(
        targetUserId: user.id,
        isLike: direction == SwipeDirection.right ||
            direction == SwipeDirection.up,
        superLike: direction == SwipeDirection.up ? 'true' : null,
      );

      if (match != null && mounted) {
        await showMatchDialog(context, match);
      }

      if (mounted) {
        setState(() => _swipedCount++);
      }

      if (_users.length - _swipedCount < 3) {
        _loadMoreUsers();
      }
    } catch (e) {
      developer.log('Error recording swipe: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content - now full screen
          _buildBody(),
          
          // Floating header overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Discover',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: _refreshFeed,
                        icon: _isRefreshing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF6B46C1),
            ),
            SizedBox(height: 16),
            Text(
              'Finding your perfect matches...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
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
      key: _feedStackKey,
      users: _users,
      currentUser: _currentUser,
      onSwipe: _onSwipe,
      onCompliment: _sendCompliment,
      remainingCompliments: _remainingCompliments,
      onEmpty: () {
        setState(() {
          _users.clear();
        });
        _refreshFeed();
      },
    );
  }
}
