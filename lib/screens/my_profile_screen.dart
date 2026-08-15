import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import 'profile_edit_screen.dart';
import 'profile_settings_screen.dart';
import '../widgets/photo_insights_panel.dart';
import '../config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _profileService = ProfileService();
  final _currentUser = Supabase.instance.client.auth.currentUser;

  Map<String, dynamic>? _profileData;
  bool _loading = true;
  bool _profilePictureRemoved = false;
  int _selectedCategory = 0;

  static const _categories = [
    'Photo insights',
    'Safety and well-being',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    try {
      final profile = await _profileService.getProfile(_currentUser!.id);
      if (profile != null && mounted) {
        setState(() {
          _profileData = profile;
          final avatarUrl = profile['avatar_url']?.toString();
          _profilePictureRemoved = avatarUrl != null && avatarUrl.isEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
    );
    await _loadProfileData();
  }

  Future<void> _openEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
    await _loadProfileData();
  }

  int? _getProfileAge() {
    final raw = _profileData?['date_of_birth'] ?? _profileData?['dob'];
    if (raw != null) {
      final dob = DateTime.tryParse(raw.toString());
      if (dob != null) {
        final now = DateTime.now();
        int age = now.year - dob.year;
        if (now.month < dob.month ||
            (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
        return age;
      }
    }
    final age = _profileData?['age'];
    if (age is int) return age;
    if (age is num) return age.toInt();
    return null;
  }

  String _getProfileImageUrl() {
    if (_profileData == null || _profilePictureRemoved) return '';

    final avatarUrl = _profileData!['avatar_url']?.toString();
    if (avatarUrl != null && avatarUrl.isNotEmpty) return avatarUrl;

    final media = _profileData!['media_urls'] as List<dynamic>?;
    if (media != null) {
      for (final item in media) {
        final url = item.toString();
        if (!ProfileService.isProfileVideoUrl(url)) return url;
      }
    }
    return '';
  }

  String _getDisplayName() {
    final firstName = _profileData?['first_name']?.toString().trim() ?? '';
    if (firstName.isEmpty) return 'Your Name';
    final age = _getProfileAge();
    return age != null ? '$firstName, $age' : firstName;
  }

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    return true;
  }

  int _calculateCompletionPercent() {
    if (_profileData == null) return 0;

    final checks = [
      _hasValue(_profileData!['first_name']),
      _getProfileAge() != null,
      _getProfileImageUrl().isNotEmpty ||
          _hasValue(_profileData!['media_urls']),
      _hasValue(_profileData!['gender']),
      _hasValue(_profileData!['bio']),
      _hasValue(_profileData!['location']),
      _hasValue(_profileData!['dating_intention']),
      _hasValue(_profileData!['height_cm']),
      _hasValue(_profileData!['work']),
      _hasValue(_profileData!['education_level']),
    ];

    final filled = checks.where((c) => c).length;
    return ((filled / checks.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final completion = _calculateCompletionPercent();

    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadProfileData,
                color: Colors.black,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildProfileSummary(completion),
                    const SizedBox(height: 28),
                    _buildCategoryBar(),
                    const SizedBox(height: 24),
                    _buildCategoryContent(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 0:
        return PhotoInsightsPanel(
          photoUrls: photoUrlsFromProfile(_profileData),
        );
      case 1:
      default:
        return _buildSafetyContent();
    }
  }

  Widget _buildSafetyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety and well-being',
          style: AppFonts.geist(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tools and tips to help you date safely and feel your best.',
          style: AppFonts.geist(
            fontSize: 15,
            color: const Color(0xFF6B6B6B),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 24),
        _buildSafetyTile(
          icon: Icons.block_outlined,
          title: 'Block and report',
          subtitle: 'Use the menu in any chat to block or report someone.',
        ),
        _buildSafetyTile(
          icon: Icons.visibility_off_outlined,
          title: 'Privacy controls',
          subtitle: 'Manage your profile visibility and data in Settings.',
          onTap: _openSettings,
        ),
        _buildSafetyTile(
          icon: Icons.support_agent_outlined,
          title: 'Support resources',
          subtitle: 'Get help with safety concerns or account issues.',
          onTap: _openSupport,
        ),
      ],
    );
  }

  Future<void> _openSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConfig.supportEmail,
      query: 'subject=RizzexAI Support',
    );
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email us at ${AppConfig.supportEmail}')),
      );
    }
  }

  Widget _buildSafetyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECECEC)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 24, color: Colors.black),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.geist(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppFonts.geist(
                        fontSize: 14,
                        color: const Color(0xFF6B6B6B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Profile',
          style: AppFonts.geist(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.help_outline, size: 26),
          color: Colors.black,
        ),
        IconButton(
          onPressed: _openSettings,
          icon: const Icon(Icons.settings_outlined, size: 26),
          color: Colors.black,
        ),
      ],
    );
  }

  Widget _buildProfileSummary(int completion) {
    final imageUrl = _getProfileImageUrl();
    final progress = completion / 100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: const Color(0xFFE8E8E8),
                  color: const Color(0xFF2B2B2B),
                ),
              ),
              GestureDetector(
                onTap: _openEditProfile,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF3F3F3),
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, size: 36, color: Color(0xFF9A9A9A))
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2B2B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completion%',
                    style: AppFonts.geist(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getDisplayName(),
                style: AppFonts.geist(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _openEditProfile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Color(0xFFD0D0D0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                ),
                child: Text(
                  completion >= 100 ? 'Edit profile' : 'Complete profile',
                  style: AppFonts.geist(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? Colors.black : const Color(0xFFD8D8D8),
                ),
              ),
              child: Text(
                _categories[index],
                style: AppFonts.geist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
