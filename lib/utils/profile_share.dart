import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user.dart';

enum ProfileShareResult { shared, copied, failed }

String buildProfileShareText(User user) {
  final lines = <String>[
    'Check out ${user.displayName} on Rizzex!',
  ];

  if (user.age != null) {
    lines.add('Age: ${user.age}');
  }

  if (user.bio != null && user.bio!.trim().isNotEmpty) {
    lines.add('');
    lines.add(user.bio!.trim());
  }

  if (user.locationCity != null || user.locationState != null) {
    lines.add('');
    lines.add('📍 ${user.location}');
  }

  if (user.allPhotos.isNotEmpty) {
    lines.add('');
    lines.add(user.allPhotos.first);
  }

  return lines.join('\n');
}

Future<ProfileShareResult> shareUserProfile(
  User user, {
  Rect? sharePositionOrigin,
}) async {
  final text = buildProfileShareText(user);
  if (text.trim().isEmpty) {
    return ProfileShareResult.failed;
  }

  final subject = user.displayName.trim().isNotEmpty
      ? '${user.displayName} on Rizzex'
      : 'Profile on Rizzex';

  try {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
        title: 'Share profile',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    return ProfileShareResult.shared;
  } catch (e, stack) {
    developer.log('Native share failed, falling back to clipboard: $e',
        error: e, stackTrace: stack);
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return ProfileShareResult.copied;
    } catch (clipboardError) {
      developer.log('Clipboard fallback failed: $clipboardError');
      return ProfileShareResult.failed;
    }
  }
}

Future<void> shareUserProfileWithFeedback(
  BuildContext context,
  User user, {
  Rect? sharePositionOrigin,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final result = await shareUserProfile(
    user,
    sharePositionOrigin: sharePositionOrigin,
  );

  if (!context.mounted || messenger == null) return;

  switch (result) {
    case ProfileShareResult.shared:
      return;
    case ProfileShareResult.copied:
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile copied to clipboard')),
      );
    case ProfileShareResult.failed:
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not share profile')),
      );
  }
}

Rect shareButtonOrigin(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  return const Rect.fromLTWH(0, 0, 1, 1);
}
