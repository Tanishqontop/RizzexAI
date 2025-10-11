import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart';

class ProfileCard extends StatefulWidget {
  final User user;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final VoidCallback? onSuperLike;
  final VoidCallback? onTap;
  final User? currentUser;

  const ProfileCard({
    super.key,
    required this.user,
    this.currentUser,
    this.onLike,
    this.onPass,
    this.onSuperLike,
    this.onTap,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPhotoIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPhotoChanged(int index) {
    setState(() {
      _currentPhotoIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.user.allPhotos;
    final hasPhotos = photos.isNotEmpty;

    final commons = _computeCommons();

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              // Remove margins to make it full-screen
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Photo section - now covers entire screen
                  if (hasPhotos)
                    _buildPhotoSection(photos)
                  else
                    _buildPlaceholderPhoto(),
                  
                  // Content section (includes gradient overlay)
                  _buildContentSection(commons),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoSection(List<String> photos) {
    return Stack(
      children: [
        // Photo carousel - full screen
        PageView.builder(
          controller: _pageController,
          onPageChanged: _onPhotoChanged,
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return CachedNetworkImage(
              imageUrl: photos[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.person,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
        
        // Photo indicators (Hinge style - small dots at top)
        if (photos.length > 1)
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(photos.length, (index) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPhotoIndex ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderPhoto() {
    return Container(
      // Make it full-screen
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.person,
          size: 100,
          color: Colors.grey,
        ),
      ),
    );
  }


  /// Compute a short list of common attributes between the displayed user and the current user.
  List<String> _computeCommons() {
    final current = widget.currentUser;
    if (current == null) return [];

    final commons = <String>[];

    // Example commons: educationLevel, jobTitle, zodiacSign, locationCity/state
    if (current.educationLevel != null && current.educationLevel == widget.user.educationLevel) {
      commons.add(current.educationLevel!);
    }

    if (current.jobTitle != null && current.jobTitle == widget.user.jobTitle) {
      commons.add(current.jobTitle!);
    }

    if (current.zodiacSign != null && current.zodiacSign == widget.user.zodiacSign) {
      commons.add(current.zodiacSign!);
    }

    if (current.locationCity != null && widget.user.locationCity != null && current.locationCity == widget.user.locationCity) {
      commons.add(current.locationCity!);
    }

    // ethnicity intersection
    if (current.ethnicity != null && widget.user.ethnicity != null) {
      final intersection = current.ethnicity!.toSet().intersection(widget.user.ethnicity!.toSet());
      if (intersection.isNotEmpty) commons.addAll(intersection.take(2));
    }

    return commons;
  }

  Widget _buildContentSection(List<String> commons) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name and Age (Hinge style)
            Row(
              children: [
                Text(
                  widget.user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                if (widget.user.age != null) ...[
                  const Text(
                    ', ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${widget.user.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Key details (Hinge style - clean and minimal)
            if (widget.user.jobTitle != null || widget.user.educationLevel != null) ...[
              Text(
                [
                  if (widget.user.jobTitle != null) widget.user.jobTitle!,
                  if (widget.user.educationLevel != null) widget.user.educationLevel!,
                ].join(' • '),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Location
            if (widget.user.location != 'Location not specified')
              Text(
                widget.user.location,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Common interests (Hinge style)
            if (commons.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  'You both ${commons.take(2).join(' & ')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.black87,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
