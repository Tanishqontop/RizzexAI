import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'auth_wrapper.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _confirmed = false;
  bool _isDeleting = false;

  static const _bodyStyle = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: Colors.black87,
  );

  Future<void> _deleteAccount() async {
    if (!_confirmed || _isDeleting) return;

    setState(() => _isDeleting = true);
    try {
      await AuthService.deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account and associated data have been deleted.'),
        ),
      );
      navigateToAuthRoot(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "We couldn't complete account deletion. Please try again. "
              'If the problem continues, contact ${AppConfig.supportEmail}.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          'Delete account',
          style: AppFonts.geist(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'By confirming the deletion of your account, all associated '
                    'information will be permanently removed. This includes:',
                    style: AppFonts.geist().merge(_bodyStyle),
                  ),
                  const SizedBox(height: 16),
                  _bullet('Personal details and profile information'),
                  _bullet('Profile photos and uploaded media'),
                  _bullet('Matches, messages, and chat history'),
                  _bullet('Preferences and customized settings'),
                  const SizedBox(height: 20),
                  Text(
                    'Account deletion is an irreversible process, and once '
                    'completed, the data cannot be recovered. Please be certain '
                    'that you want to proceed with this action.',
                    style: AppFonts.geist().merge(_bodyStyle),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Do you want to delete your account?',
                    style: AppFonts.geist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _isDeleting
                        ? null
                        : () => setState(() => _confirmed = !_confirmed),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _confirmed,
                              onChanged: _isDeleting
                                  ? null
                                  : (value) =>
                                      setState(() => _confirmed = value ?? false),
                              activeColor: Colors.black,
                              side: const BorderSide(color: Colors.black54, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Yes, delete my account',
                              style: AppFonts.geist(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        _confirmed && !_isDeleting ? _deleteAccount : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      disabledBackgroundColor: Colors.black26,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Delete account',
                            style: AppFonts.geist(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isDeleting
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppFonts.geist(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: AppFonts.geist(fontSize: 15, height: 1.5, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              text,
              style: AppFonts.geist().merge(_bodyStyle),
            ),
          ),
        ],
      ),
    );
  }
}
