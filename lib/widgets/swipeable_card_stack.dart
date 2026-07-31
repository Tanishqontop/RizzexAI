import 'package:flutter/material.dart';
import 'feed_profile_view.dart';
import '../models/user.dart';

class SwipeableCardStack extends StatefulWidget {
  final List<User> users;
  final int currentIndex;
  final User? currentUser;
  final Function(User user, SwipeDirection direction)? onSwipe;
  final Future<bool> Function(User user, SwipeDirection direction)? onSwipeAsync;
  final VoidCallback? onEmpty;
  final Widget? emptyWidget;
  final void Function(User user)? onCompliment;
  final int remainingCompliments;
  final int remainingSuperLikes;

  const SwipeableCardStack({
    super.key,
    required this.users,
    this.currentIndex = 0,
    this.currentUser,
    this.onSwipe,
    this.onSwipeAsync,
    this.onEmpty,
    this.emptyWidget,
    this.onCompliment,
    this.remainingCompliments = 0,
    this.remainingSuperLikes = 0,
  });

  @override
  State<SwipeableCardStack> createState() => SwipeableCardStackState();
}

enum SwipeDirection { left, right, up }

class SwipeableCardStackState extends State<SwipeableCardStack> {
  bool _isAnimating = false;

  int get _currentIndex => widget.currentIndex;

  @override
  void didUpdateWidget(SwipeableCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users) {
      _isAnimating = false;
    }
  }

  Future<void> _swipeCard(SwipeDirection direction) async {
    if (_isAnimating || _currentIndex >= widget.users.length) return;

    _isAnimating = true;
    final user = widget.users[_currentIndex];

    var shouldAdvance = true;
    if (widget.onSwipeAsync != null) {
      shouldAdvance = await widget.onSwipeAsync!(user, direction);
    } else {
      widget.onSwipe?.call(user, direction);
    }

    if (!mounted) return;

    if (shouldAdvance && _currentIndex + 1 >= widget.users.length) {
      widget.onEmpty?.call();
    }

    setState(() => _isAnimating = false);
  }

  void _swipeLeft() {
    _swipeCard(SwipeDirection.left);
  }

  void _swipeRight() {
    _swipeCard(SwipeDirection.right);
  }

  void _swipeUp() {
    if (widget.remainingSuperLikes <= 0) {
      _swipeCard(SwipeDirection.up);
      return;
    }
    _swipeCard(SwipeDirection.up);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty || _currentIndex >= widget.users.length) {
      return widget.emptyWidget ?? _buildEmptyWidget();
    }

    final user = widget.users[_currentIndex];
    final canSuperLike = widget.remainingSuperLikes > 0;

    return Stack(
      children: [
        FeedProfileView(
          key: ValueKey(user.id),
          user: user,
          currentUser: widget.currentUser,
          onCompliment: widget.onCompliment != null
              ? () => widget.onCompliment!(user)
              : null,
          onSuperLike: canSuperLike ? _swipeUp : () => _swipeCard(SwipeDirection.up),
        ),
        FeedProfileActions(
          onPass: _swipeLeft,
          onLike: _swipeRight,
        ),
      ],
    );
  }

  Widget _buildEmptyWidget() {
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
            'No more profiles',
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
            onPressed: widget.onEmpty,
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
}
