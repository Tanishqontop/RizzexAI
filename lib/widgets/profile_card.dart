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
                  
                  // Photo indicators
                  if (hasPhotos && photos.length > 1)
                    _buildPhotoIndicators(photos.length),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoSection(List<String> photos) {
    return SizedBox(
      // fill available area so the image covers the card fully
      width: double.infinity,
      height: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPhotoChanged,
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: photos[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6B46C1),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Commons row - more prominent
            if (commons.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'You both ${commons.take(2).join(' & ')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Name and age - more prominent
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.user.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.user.age != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${widget.user.age}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Location
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.user.location,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Bio
            if (widget.user.bio != null && widget.user.bio!.isNotEmpty)
              Text(
                widget.user.bio!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            
            const SizedBox(height: 16),
            
            // Additional info chips
            _buildInfoChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChips() {
    List<Widget> chips = [];
    
    if (widget.user.heightFeet != null) {
      chips.add(_buildInfoChip(widget.user.height));
    }
    
    if (widget.user.zodiacSign != null) {
      chips.add(_buildInfoChip(widget.user.zodiacSign!));
    }
    
    if (widget.user.educationLevel != null) {
      chips.add(_buildInfoChip(widget.user.educationLevel!));
    }
    
    if (widget.user.jobTitle != null) {
      chips.add(_buildInfoChip(widget.user.jobTitle!));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }


  Widget _buildPhotoIndicators(int photoCount) {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${_currentPhotoIndex + 1}/$photoCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
