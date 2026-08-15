import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_match.dart';
import '../utils/image_url_utils.dart';

Future<void> showMatchDialog(BuildContext context, UserMatch match) {
  final user = match.matchedUser;
  final photoUrl = firstValidImageUrl([
    user.avatarUrl,
    ...?user.profilePhotos,
  ]);

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "It's a Match!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B46C1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You and ${user.displayName} liked each other',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF6B46C1).withOpacity(0.15),
              backgroundImage:
                  photoUrl != null ? CachedNetworkImageProvider(photoUrl) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, size: 48, color: Color(0xFF6B46C1))
                  : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Keep Swiping',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
