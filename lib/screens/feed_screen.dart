import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/feed_service.dart';
import '../widgets/swipeable_card_stack.dart';
import '../widgets/feed_action_buttons.dart';
import 'dart:developer' as developer;

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FeedService _feedService = FeedService();
  List<User> _users = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
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

  void _onSwipe(User user, SwipeDirection direction) async {
    try {
      await _feedService.recordSwipe(
        targetUserId: user.id,
        isLike: direction == SwipeDirection.right || direction == SwipeDirection.up,
        superLike: direction == SwipeDirection.up ? 'true' : null,
      );
      
      // Load more users if we're running low
      if (_users.length - _getCurrentCardIndex() < 3) {
        _loadMoreUsers();
      }
    } catch (e) {
      developer.log('Error recording swipe: $e');
    }
  }

  void _onPass() {
    // This will be handled by the swipe gesture
  }

  void _onLike() {
    // This will be handled by the swipe gesture
  }

  void _onSuperLike() {
    // This will be handled by the swipe gesture
  }

  int _getCurrentCardIndex() {
    // This would need to be tracked by the SwipeableCardStack
    // For now, we'll estimate based on the number of users
    return _users.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Color(0xFF6B46C1),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Discover',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B46C1),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _refreshFeed,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6B46C1),
                            ),
                          )
                        : const Icon(
                            Icons.refresh,
                            color: Color(0xFF6B46C1),
                          ),
                  ),
                ],
              ),
            ),
            
            // Main content
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
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

    return Column(
      children: [
        // Card stack
        Expanded(
          child: SwipeableCardStack(
            users: _users,
            onSwipe: _onSwipe,
            onEmpty: () {
              setState(() {
                _users.clear();
              });
              _refreshFeed();
            },
          ),
        ),
        
        // Action buttons
        FeedActionButtonsWithLabels(
          onPass: _onPass,
          onLike: _onLike,
          onSuperLike: _onSuperLike,
          isLoading: _isRefreshing,
        ),
      ],
    );
  }
}
