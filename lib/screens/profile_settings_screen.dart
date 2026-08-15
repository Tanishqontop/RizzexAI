import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'auth_wrapper.dart';
import 'delete_account_screen.dart';
import 'profile_edit_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  Future<void> _openEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=RizzexAI Support',
    );
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email us at $email')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.signOut();
      if (mounted) {
        navigateToAuthRoot(context);
      }
    }
  }

  void _openDeleteAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
    );
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
          'Settings',
          style: AppFonts.geist(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(
              'Edit Profile',
              style: AppFonts.geist(fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Policy', style: AppFonts.geist()),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(AppConfig.privacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text('Terms of Service', style: AppFonts.geist()),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(AppConfig.termsOfServiceUrl),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text('Child Safety Standards', style: AppFonts.geist()),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(AppConfig.childSafetyStandardsUrl),
          ),
          ListTile(
            leading: const Icon(Icons.link_outlined),
            title: Text('Delete Account (Web)', style: AppFonts.geist()),
            subtitle: Text(
              'Alternative request form if you cannot use in-app deletion',
              style: AppFonts.geist(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(AppConfig.externalDeleteAccountUrl),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text('Contact Support', style: AppFonts.geist()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openEmail(AppConfig.supportEmail),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Log Out',
              style: AppFonts.geist(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            onTap: _logout,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: Text(
              'Delete Account',
              style: AppFonts.geist(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            onTap: _openDeleteAccount,
          ),
        ],
      ),
    );
  }
}
