import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'profile_card.dart';
import '../models/user.dart';

class SwipeableCardStack extends StatefulWidget {
  final List<User> users;
  final User? currentUser;
  final Function(User user, SwipeDirection direction)? onSwipe;
  final VoidCallback? onEmpty;
  final Widget? emptyWidget;
  final void Function(User user)? onCompliment;
  final int remainingCompliments;

  const SwipeableCardStack({
    super.key,
    required this.users,
    this.currentUser,
    this.onSwipe,
    this.onEmpty,
    this.emptyWidget,
    this.onCompliment,
    this.remainingCompliments = 0,
  });

  @override
  State<SwipeableCardStack> createState() => _SwipeableCardStackState();
}

enum SwipeDirection { left, right, up }

class _SwipeableCardStackState extends State<SwipeableCardStack>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isAnimating = false;
  Offset _panStartPosition = Offset.zero;
  double _dragOffset = 0;

  late AnimationController _exitController;
  Animation<double>? _exitAnimation;

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SwipeableCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.users != widget.users) {
      _currentIndex = 0;
      _dragOffset = 0;
      _isAnimating = false;
      _exitController.reset();
    }
  }

  double get _dragRotation => (_dragOffset / 1000).clamp(-0.15, 0.15);

  double get _overlayOpacity => (_dragOffset.abs() / 120).clamp(0.0, 1.0);

  void _resetDrag() {
    _exitController.reset();
    setState(() {
      _dragOffset = 0;
      _isAnimating = false;
    });
  }

  void _animateDragTo(double target, VoidCallback onComplete) {
    _exitController.stop();
    _exitController.reset();

    _exitAnimation = Tween<double>(
      begin: _dragOffset,
      end: target,
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeOut,
    ));

    void listener() {
      setState(() {
        _dragOffset = _exitAnimation!.value;
      });
    }

    _exitAnimation!.addListener(listener);

    _exitController.forward(from: 0).then((_) {
      _exitAnimation!.removeListener(listener);
      _exitController.reset();
      onComplete();
    });
  }

  void _swipeCard(SwipeDirection direction) {
    if (_isAnimating || _currentIndex >= widget.users.length) return;

    _isAnimating = true;
    final user = widget.users[_currentIndex];
    final screenWidth = MediaQuery.of(context).size.width;

    final target = switch (direction) {
      SwipeDirection.right => screenWidth * 1.5,
      SwipeDirection.left => -screenWidth * 1.5,
      SwipeDirection.up => _dragOffset,
    };

    void finishSwipe() {
      if (!mounted) return;
      setState(() {
        _currentIndex++;
        _dragOffset = 0;
        _isAnimating = false;
      });

      widget.onSwipe?.call(user, direction);

      if (_currentIndex >= widget.users.length) {
        widget.onEmpty?.call();
      }
    }

    if (direction == SwipeDirection.up) {
      finishSwipe();
      return;
    }

    _animateDragTo(target, finishSwipe);
  }

  void _swipeLeft() => _swipeCard(SwipeDirection.left);

  void _swipeRight() => _swipeCard(SwipeDirection.right);

  void _swipeUp() => _swipeCard(SwipeDirection.up);

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;

    final currentPosition = details.localPosition;
    final totalDx = currentPosition.dx - _panStartPosition.dx;
    final totalDy = currentPosition.dy - _panStartPosition.dy;

    if (totalDx.abs() > totalDy.abs() && totalDx.abs() > 10) {
      setState(() {
        _dragOffset = totalDx;
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isAnimating) return;

    final velocityX = details.velocity.pixelsPerSecond.dx;
    final velocityY = details.velocity.pixelsPerSecond.dy;
    final totalDx = _dragOffset;
    final threshold = MediaQuery.of(context).size.width * 0.25;

    if (totalDx > threshold || velocityX > 500) {
      _swipeRight();
    } else if (totalDx < -threshold || velocityX < -500) {
      _swipeLeft();
    } else if (velocityY < -500 && totalDx.abs() < 30) {
      _swipeUp();
    } else {
      _animateDragTo(0, _resetDrag);
    }
  }

  Widget _buildSwipeOverlay() {
    if (_dragOffset > 20) {
      return Positioned.fill(
        child: IgnorePointer(
          child: Container(
            color: Colors.green.withOpacity(0.15 * _overlayOpacity),
            child: Center(
              child: Opacity(
                opacity: _overlayOpacity,
                child: const Text(
                  '❤️',
                  style: TextStyle(fontSize: 96),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_dragOffset < -20) {
      return Positioned.fill(
        child: IgnorePointer(
          child: Container(
            color: Colors.red.withOpacity(0.15 * _overlayOpacity),
            child: Center(
              child: Opacity(
                opacity: _overlayOpacity,
                child: const Text(
                  '👎',
                  style: TextStyle(fontSize: 96),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty || _currentIndex >= widget.users.length) {
      return widget.emptyWidget ?? _buildEmptyWidget();
    }

    return Stack(
      children: [
        ...List.generate(
          math.min(3, widget.users.length - _currentIndex),
          (index) {
            final userIndex = _currentIndex + index;
            if (userIndex >= widget.users.length) {
              return const SizedBox.shrink();
            }

            final user = widget.users[userIndex];
            final isTopCard = index == 0;

            return Positioned.fill(
              child: Transform.scale(
                scale: isTopCard ? 1.0 : 0.95 - (index * 0.05),
                child: Transform.translate(
                  offset: Offset(0, index * 8.0),
                  child: Opacity(
                    opacity: isTopCard ? 1.0 : 0.8 - (index * 0.2),
                    child: ProfileCard(
                      user: user,
                      currentUser: widget.currentUser,
                      onTap: isTopCard ? () => _showUserDetails(user) : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (_currentIndex < widget.users.length)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (details) {
                _panStartPosition = details.localPosition;
              },
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              child: Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: Transform.rotate(
                  angle: _dragRotation,
                  child: Stack(
                    children: [
                      ProfileCard(
                        user: widget.users[_currentIndex],
                        currentUser: widget.currentUser,
                        onTap: () =>
                            _showUserDetails(widget.users[_currentIndex]),
                      ),
                      _buildSwipeOverlay(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_currentIndex < widget.users.length && widget.onCompliment != null)
          Positioned(
            left: 20,
            bottom: 120,
            child: _buildComplimentButton(
              remaining: widget.remainingCompliments,
              onPressed: widget.remainingCompliments > 0
                  ? () => widget.onCompliment!(widget.users[_currentIndex])
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildComplimentButton({
    required int remaining,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: onPressed != null
                ? const Color(0xFF6B46C1)
                : Colors.grey.withOpacity(0.6),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💬', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Compliment ($remaining left)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
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
            onPressed: () {
              setState(() {
                _currentIndex = 0;
              });
            },
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

  void _showUserDetails(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 20),
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.location,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.bio!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                  ],
                  _buildDetailSection('Basic Info', [
                    if (user.age != null) 'Age: ${user.age}',
                    if (user.heightFeet != null) 'Height: ${user.height}',
                    if (user.zodiacSign != null) 'Zodiac: ${user.zodiacSign}',
                  ]),
                  _buildDetailSection('Education & Work', [
                    if (user.educationLevel != null)
                      'Education: ${user.educationLevel}',
                    if (user.schoolName != null) 'School: ${user.schoolName}',
                    if (user.jobTitle != null) 'Job: ${user.jobTitle}',
                    if (user.workCompany != null) 'Company: ${user.workCompany}',
                  ]),
                  _buildDetailSection('Lifestyle', [
                    if (user.drinking != null) 'Drinking: ${user.drinking}',
                    if (user.smokingTobacco != null)
                      'Smoking: ${user.smokingTobacco}',
                    if (user.wantsChildren != null)
                      'Wants children: ${user.wantsChildren}',
                    if (user.hasChildren != null)
                      'Has children: ${user.hasChildren}',
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> details) {
    final validDetails = details.where((d) => d.isNotEmpty).toList();
    if (validDetails.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...validDetails.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                detail,
                style: const TextStyle(fontSize: 16),
              ),
            )),
        const SizedBox(height: 20),
      ],
    );
  }
}
