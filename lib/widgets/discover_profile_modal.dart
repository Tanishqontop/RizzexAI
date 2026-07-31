import 'package:flutter/material.dart';
import '../models/user.dart';
import 'feed_profile_view.dart';

Future<void> showDiscoverProfileModal({
  required BuildContext context,
  required User user,
  User? currentUser,
  required VoidCallback onLike,
  VoidCallback? onPass,
  VoidCallback? onCompliment,
  VoidCallback? onSuperLike,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Material(
              color: const Color(0xFFF3F3F3),
              child: Stack(
                children: [
                  FeedProfileView(
                    user: user,
                    currentUser: currentUser,
                    scrollController: scrollController,
                    onCompliment: onCompliment,
                    onSuperLike: onSuperLike != null
                        ? () {
                            Navigator.pop(sheetContext);
                            onSuperLike();
                          }
                        : null,
                  ),
                  FeedProfileActions(
                    onPass: onPass ??
                        () {
                          Navigator.pop(sheetContext);
                        },
                    onLike: () {
                      Navigator.pop(sheetContext);
                      onLike();
                    },
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 2,
                            child: IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close, size: 22),
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
