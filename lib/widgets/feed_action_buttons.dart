import 'package:flutter/material.dart';

class FeedActionButtons extends StatelessWidget {
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final VoidCallback? onSuperLike;
  final bool isLoading;

  const FeedActionButtons({
    super.key,
    this.onPass,
    this.onLike,
    this.onSuperLike,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          _buildActionButton(
            icon: Icons.close,
            color: Colors.red[400]!,
            onPressed: isLoading ? null : onPass,
            size: 24,
          ),
          
          // Super like button
          _buildActionButton(
            icon: Icons.star,
            color: Colors.blue[400]!,
            onPressed: isLoading ? null : onSuperLike,
            size: 28,
            isSpecial: true,
          ),
          
          // Like button
          _buildActionButton(
            icon: Icons.favorite,
            color: Colors.green[400]!,
            onPressed: isLoading ? null : onLike,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required double size,
    bool isSpecial = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isSpecial ? 60 : 50,
        height: isSpecial ? 60 : 50,
        decoration: BoxDecoration(
          color: onPressed != null ? color : Colors.grey[300],
          shape: BoxShape.circle,
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: onPressed != null ? Colors.white : Colors.grey[500],
          size: size,
        ),
      ),
    );
  }
}

class FeedActionButtonsWithLabels extends StatelessWidget {
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final VoidCallback? onSuperLike;
  final bool isLoading;

  const FeedActionButtonsWithLabels({
    super.key,
    this.onPass,
    this.onLike,
    this.onSuperLike,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pass button
              _buildActionButtonWithLabel(
                icon: Icons.close,
                label: 'Pass',
                color: Colors.red[400]!,
                onPressed: isLoading ? null : onPass,
                size: 24,
              ),
              
              // Super like button
              _buildActionButtonWithLabel(
                icon: Icons.star,
                label: 'Super Like',
                color: Colors.blue[400]!,
                onPressed: isLoading ? null : onSuperLike,
                size: 28,
                isSpecial: true,
              ),
              
              // Like button
              _buildActionButtonWithLabel(
                icon: Icons.favorite,
                label: 'Like',
                color: Colors.green[400]!,
                onPressed: isLoading ? null : onLike,
                size: 24,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Swipe hint
          Text(
            'Swipe left to pass, right to like, up for super like',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonWithLabel({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    required double size,
    bool isSpecial = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: isSpecial ? 60 : 50,
            height: isSpecial ? 60 : 50,
            decoration: BoxDecoration(
              color: onPressed != null ? color : Colors.grey[300],
              shape: BoxShape.circle,
              boxShadow: onPressed != null
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: onPressed != null ? Colors.white : Colors.grey[500],
              size: size,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: onPressed != null ? color : Colors.grey[500],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
