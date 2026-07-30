import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatImageViewer extends StatelessWidget {
  final String imageUrl;
  final bool viewOnce;
  const ChatImageViewer({
    super.key,
    required this.imageUrl,
    this.viewOnce = false,
  });

  static Future<void> open(
    BuildContext context, {
    required String imageUrl,
    bool viewOnce = false,
    Future<void> Function()? onOpened,
  }) async {
    try {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (context) => ChatImageViewer(
          imageUrl: imageUrl,
          viewOnce: viewOnce,
        ),
      );
    } finally {
      if (viewOnce && onOpened != null) {
        await onOpened();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(
                  color: Colors.white,
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  if (viewOnce) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'View once',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
