import 'package:rizzexai/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import 'profile_edit_screen.dart';
import 'profile_settings_screen.dart';
import '../widgets/spotlight_sheet.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _profileService = ProfileService();
  final _currentUser = Supabase.instance.client.auth.currentUser;
  final _promoController = PageController(viewportFraction: 0.88);

  Map<String, dynamic>? _profileData;
  bool _loading = true;
  bool _profilePictureRemoved = false;
  int _selectedCategory = 0;
  bool _isRizzMaxSelected = false;

  static const _categories = [
    'Pay plan',
    'Photo insights',
    'Safety and well-being',
  ];

  static const _rizzPlusTagline =
      'Best for: People looking to meet and chat.';

  static const _rizzPlusFeatures = [
    'Unlimited Likes',
    'Unlimited Matches',
    'Unlimited Messaging',
    'See Who Liked You',
    'Unlimited Rewinds',
    '5 Super Likes per week',
    '1 Profile Boost per month',
    'AI Bio Generator',
    'AI Profile Review',
    'AI Conversation Starters',
    'AI Pickup Line Generator',
    'Advanced Search Filters',
    'Change Location (up to 5 cities/month)',
    'Verified Profile Badge',
    'Ad-Free Experience',
  ];

  static const _rizzMaxSections = [
    _PlanFeatureSection(
      title: 'Visibility',
      features: [
        'Priority Profile Ranking',
        'Unlimited Profile Boosts',
        'Unlimited Super Likes',
        'Priority Like Delivery',
        'New User Spotlight',
      ],
    ),
    _PlanFeatureSection(
      title: 'Privacy',
      features: [
        'Incognito Mode',
        'Control who can message you',
        'Hide online status',
        'Read Receipts',
      ],
    ),
    _PlanFeatureSection(
      title: 'AI Features',
      features: [
        'AI Dating Coach',
        'AI Chat Assistant (reply suggestions)',
        'AI Conversation Analysis',
        'AI Flirting Coach',
        'AI Date Planner',
        'AI Compatibility Score',
        'AI Red Flag Detection',
        'AI Profile Optimization',
        'AI Voice Icebreakers',
      ],
    ),
    _PlanFeatureSection(
      title: 'Insights',
      features: [
        'Weekly Dating Analytics',
        'Profile Views',
        'Like Rate',
        'Match Rate',
        'Response Rate',
        'Conversation Success Rate',
        'AI Improvement Tips',
      ],
    ),
    _PlanFeatureSection(
      title: 'Exclusives',
      features: [
        'Exclusive RizzMax Badge',
        'Premium Profile Themes',
        'Early Access to New Features',
        'Priority Customer Support',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    if (_currentUser == null) return;

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
                    _buildActionCards(),
                    const SizedBox(height: 24),
                    _buildPromoCarousel(),
                    const SizedBox(height: 28),
                    _buildFeatureComparison(),
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

  Widget _buildActionCards() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showSpotlightSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD447),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Spotlight',
                textAlign: TextAlign.center,
                style: AppFonts.geist(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Stand out',
                textAlign: TextAlign.center,
                style: AppFonts.geist(
                  fontSize: 13,
                  color: const Color(0xFF4A4A4A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCarousel() {
    return SizedBox(
      height: 268,
      child: PageView(
        controller: _promoController,
        children: [
          _buildPremiumCard(
            badge: 'RIZZMAX',
            color: const Color(0xFFFFD447),
            text:
                'Get the VIP treatment with priority visibility, advanced AI, and exclusive perks.',
            buttonLabel: 'Explore RizzMax',
            onExplore: () => setState(() => _isRizzMaxSelected = true),
          ),
          _buildPremiumCard(
            badge: 'RIZZ+',
            color: Colors.white,
            text:
                'Unlimited likes, matches, and messaging — plus AI tools to level up your profile.',
            buttonLabel: 'Explore Rizz+',
            bordered: true,
            onExplore: () => setState(() => _isRizzMaxSelected = false),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({
    required String badge,
    required Color color,
    required String text,
    required String buttonLabel,
    VoidCallback? onExplore,
    bool bordered = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: bordered ? Border.all(color: const Color(0xFFE0E0E0)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.rotate(
            angle: -0.08,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: Colors.black,
              child: Text(
                badge,
                style: AppFonts.geist(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                  color: bordered ? Colors.white : const Color(0xFFFFD447),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.geist(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.25,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onExplore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                buttonLabel,
                style: AppFonts.geist(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              'What you get:',
              style: AppFonts.geist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            _buildPlanToggle('Rizz+', !_isRizzMaxSelected, () {
              setState(() => _isRizzMaxSelected = false);
            }),
            _buildPlanToggle('RizzMax', _isRizzMaxSelected, () {
              setState(() => _isRizzMaxSelected = true);
            }),
          ],
        ),
        const SizedBox(height: 12),
        if (!_isRizzMaxSelected) ...[
          Text(
            _rizzPlusTagline,
            style: AppFonts.geist(
              fontSize: 14,
              color: const Color(0xFF6B6B6B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ..._rizzPlusFeatures.map(_buildFeatureRow),
        ] else ...[
          Text(
            'Everything in Rizz+ plus:',
            style: AppFonts.geist(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          for (final section in _rizzMaxSections) ...[
            _buildFeatureSectionHeader(section.title),
            ...section.features.map(_buildFeatureRow),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  Widget _buildFeatureSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: AppFonts.geist(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6B46C1),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildPlanToggle(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: AppFonts.geist(
          fontSize: 16,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: active ? Colors.black : const Color(0xFFB0B0B0),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFECECEC)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    feature,
                    style: AppFonts.geist(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
              ],
            ),
          ),
          const Icon(Icons.check, color: Colors.black, size: 24),
        ],
      ),
    );
  }
}

class _PlanFeatureSection {
  final String title;
  final List<String> features;

  const _PlanFeatureSection({
    required this.title,
    required this.features,
  });
}
