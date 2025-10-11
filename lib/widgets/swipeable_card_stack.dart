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

  const SwipeableCardStack({
    super.key,
    required this.users,
    this.currentUser,
    this.onSwipe,
    this.onEmpty,
    this.emptyWidget,
  });

  @override
  State<SwipeableCardStack> createState() => _SwipeableCardStackState();
}

enum SwipeDirection { left, right, up }

class _SwipeableCardStackState extends State<SwipeableCardStack>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;
  late List<Animation<double>> _rotationAnimations;
  late List<Animation<double>> _scaleAnimations;
  
  int _currentIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.users.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(1.5, 0),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _rotationAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: 0.1,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 0.8,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _swipeCard(SwipeDirection direction) {
    if (_isAnimating || _currentIndex >= widget.users.length) return;

    _isAnimating = true;
    final user = widget.users[_currentIndex];
    
    // Animate the card out
    _controllers[_currentIndex].forward().then((_) {
      if (mounted) {
        setState(() {
          _currentIndex++;
          _isAnimating = false;
        });
        
        widget.onSwipe?.call(user, direction);
        
        if (_currentIndex >= widget.users.length) {
          widget.onEmpty?.call();
        }
      }
    });
  }

  void _swipeLeft() {
    _swipeCard(SwipeDirection.left);
  }

  void _swipeRight() {
    _swipeCard(SwipeDirection.right);
  }

  void _swipeUp() {
    _swipeCard(SwipeDirection.up);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.users.isEmpty || _currentIndex >= widget.users.length) {
      return widget.emptyWidget ?? _buildEmptyWidget();
    }

    return Stack(
      children: [
        // Background cards (stacked behind) - now full-screen
        ...List.generate(
          math.min(3, widget.users.length - _currentIndex),
          (index) {
            final userIndex = _currentIndex + index;
            if (userIndex >= widget.users.length) return const SizedBox.shrink();
            
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
        
        // Top card with enhanced swipe gestures
        if (_currentIndex < widget.users.length)
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) {
                if (_isAnimating) return;
                
                final delta = details.delta.dx;
                
                // Update card position based on pan - more sensitive
                if (delta.abs() > 5) {
                  final progress = (delta / 150).clamp(-1.0, 1.0);
                  _controllers[_currentIndex].value = progress.abs();
                }
              },
              onPanEnd: (details) {
                if (_isAnimating) return;
                
                final velocity = details.velocity.pixelsPerSecond.dx;
                final delta = details.velocity.pixelsPerSecond.dy;
                
                // More sensitive swipe detection for better UX
                if (velocity.abs() > 300 || delta.abs() > 300) {
                  if (velocity > 0) {
                    // Right swipe = Like
                    _swipeRight();
                  } else if (velocity < 0) {
                    // Left swipe = Dislike
                    _swipeLeft();
                  } else if (delta < -300) {
                    // Up swipe = Super Like
                    _swipeUp();
                  }
                } else {
                  // Reset card position if swipe wasn't strong enough
                  _controllers[_currentIndex].reverse();
                }
              },
              child: AnimatedBuilder(
                animation: _controllers[_currentIndex],
                builder: (context, child) {
                  final user = widget.users[_currentIndex];
                  final progress = _controllers[_currentIndex].value;
                  
                  return Transform.translate(
                    offset: _animations[_currentIndex].value * progress,
                    child: Transform.rotate(
                      angle: _rotationAnimations[_currentIndex].value * progress,
                      child: Transform.scale(
                        scale: _scaleAnimations[_currentIndex].value,
                        child: ProfileCard(
                          user: user,
                          currentUser: widget.currentUser,
                          onTap: () => _showUserDetails(user),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
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
                  // Handle bar
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
                  
                  // User details
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
                  
                  // Additional details
                  _buildDetailSection('Basic Info', [
                    if (user.age != null) 'Age: ${user.age}',
                    if (user.heightFeet != null) 'Height: ${user.height}',
                    if (user.zodiacSign != null) 'Zodiac: ${user.zodiacSign}',
                  ]),
                  
                  _buildDetailSection('Education & Work', [
                    if (user.educationLevel != null) 'Education: ${user.educationLevel}',
                    if (user.schoolName != null) 'School: ${user.schoolName}',
                    if (user.jobTitle != null) 'Job: ${user.jobTitle}',
                    if (user.workCompany != null) 'Company: ${user.workCompany}',
                  ]),
                  
                  _buildDetailSection('Lifestyle', [
                    if (user.drinking != null) 'Drinking: ${user.drinking}',
                    if (user.smokingTobacco != null) 'Smoking: ${user.smokingTobacco}',
                    if (user.wantsChildren != null) 'Wants children: ${user.wantsChildren}',
                    if (user.hasChildren != null) 'Has children: ${user.hasChildren}',
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
