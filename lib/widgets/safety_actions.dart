import 'package:flutter/material.dart';
import 'package:rizzexai/theme/app_typography.dart';
import '../services/safety_service.dart';

Future<void> showReportUserSheet(
  BuildContext context, {
  required String userId,
  required String userName,
  VoidCallback? onCompleted,
}) async {
  const reasons = [
    'Inappropriate photos',
    'Harassment or bullying',
    'Spam or scam',
    'Underage user',
    'Other',
  ];

  var selectedReason = reasons.first;
  final detailsController = TextEditingController();

  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report $userName',
                  style: AppFonts.geist(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tell us what happened. Reports are reviewed by our team.',
                  style: AppFonts.geist(
                    fontSize: 14,
                    color: const Color(0xFF6B6B6B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                ...reasons.map(
                  (reason) => RadioListTile<String>(
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedReason = value);
                    },
                    title: Text(reason, style: AppFonts.geist(fontSize: 15)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      try {
                        await SafetyService().reportUser(
                          reportedUserId: userId,
                          reason: selectedReason,
                          details: detailsController.text,
                        );
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not submit report: $e')),
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Submit report'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  detailsController.dispose();

  if (submitted == true && context.mounted) {
    onCompleted?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted. Thank you.')),
    );
  }
}

Future<bool> confirmBlockUser(
  BuildContext context, {
  required String userName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Block $userName?'),
      content: const Text(
        'They will no longer appear in your feed or chats, and your match will be removed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Block'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

Future<void> blockUserAndNotify(
  BuildContext context, {
  required String userId,
  required String userName,
  VoidCallback? onBlocked,
}) async {
  final confirmed = await confirmBlockUser(context, userName: userName);
  if (!confirmed || !context.mounted) return;

  try {
    await SafetyService().blockUser(userId);
    onBlocked?.call();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$userName has been blocked')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not block user: $e')),
      );
    }
  }
}

Future<void> showSafetyActionsSheet(
  BuildContext context, {
  required String userId,
  required String userName,
  VoidCallback? onBlocked,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Report'),
            onTap: () {
              Navigator.pop(context);
              showReportUserSheet(
                context,
                userId: userId,
                userName: userName,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('Block', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await blockUserAndNotify(
                context,
                userId: userId,
                userName: userName,
                onBlocked: onBlocked,
              );
            },
          ),
        ],
      ),
    ),
  );
}
