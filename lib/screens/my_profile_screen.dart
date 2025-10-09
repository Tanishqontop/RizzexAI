import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';

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
  bool _saving = false;
  bool _profilePictureRemoved = false;

  // Helpers
  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  // Onboarding option sets (reused here)
  static const List<String> _pronounOptions = [
    'she', 'her', 'hers', 'he', 'him', 'his', 'they', 'them'
  ];
  static const List<String> _genderOptions = ['Man', 'Woman', 'Non-binary'];
  static const List<String> _sexualityOptions = [
    'Prefer not to say',
    'Straight',
    'Gay',
    'Lesbian',
    'Bisexual',
    'Allosexual',
    'Androsexual',
    'Asexual',
    'Autosexual',
    'Bicurious',
  ];
  static const List<String> _likeToDateOptions = [
    'Men', 'Women', 'Non-binary people', 'Everyone'
  ];
  static const List<String> _datingIntentionOptions = [
    'Life partner',
    'Long-term relationship',
    'Long-term relationship, open to short',
    'Short-term relationship, open to long',
    'Short-term relationship',
    'Figuring out my dating goals',
    'Prefer not to say',
  ];
  static const List<String> _relationshipTypeOptions = [
    'Monogamy', 'Non-monogamy', 'Figuring out my relationship type'
  ];
  static const List<String> _ethnicityOptions = [
    'Black/African Descent',
    'East Asian',
    'Hispanic/Latino',
    'Middle Eastern',
    'Native American',
    'Pacific Islander',
    'South Asian',
    'Southeast Asian',
    'White/Caucasian',
    'Other',
  ];
  static const List<String> _childrenOptions = [
    "Don't have children", 'Have children', 'Prefer not to say'
  ];
  static const List<String> _familyPlanOptions = [
    "Don't want children",
    'Want children',
    'Open to children',
    'Not sure yet',
    'Prefer not to say',
  ];
  static const List<String> _educationLevelOptions = [
    'Secondary school', 'Undergrad', 'Postgrad', 'Prefer not to say'
  ];
  static const List<String> _religiousBeliefOptions = [
    'Agnostic',
    'Atheist',
    'Buddhist',
    'Catholic',
    'Christian',
    'Hindu',
    'Jewish',
    'Muslim',
    'Sikh',
    'Spiritual',
    'Other',
  ];
  static const List<String> _politicalBeliefOptions = [
    'Liberal', 'Moderate', 'Conservative', 'Not political', 'Other', 'Prefer not to say'
  ];
  static const List<String> _yesSometimesNoOptions = [
    'Yes', 'Sometimes', 'No', 'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }


  Future<void> _loadProfileData() async {
    if (_currentUser == null) return;
    
    setState(() => _loading = true);
    try {
      final profile = await _profileService.getProfile(_currentUser!.id);
      if (profile != null) {
        setState(() {
          _profileData = profile;
          // Check if user has explicitly removed their profile picture
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
      setState(() => _loading = false);
    }
  }


  Future<void> _updateProfilePicture() async {
    if (_currentUser == null) return;
    
    // Show image source selection
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF6B46C1)),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF6B46C1)),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadImage(ImageSource.camera);
                },
              ),
              if (_getProfileImageUrl().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Profile Picture'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _removeProfilePicture();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    if (_currentUser == null) return;
    
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: source,
      imageQuality: 85, // Compress image for better performance
      maxWidth: 1024,
      maxHeight: 1024,
    );
    
    if (result != null) {
      setState(() => _saving = true);
      try {
        final file = File(result.path);
        
        // Validate file size (max 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image too large. Please choose an image smaller than 5MB.')),
            );
          }
          return;
        }
        
        final url = await _profileService.uploadProfileMedia(
          userId: _currentUser!.id,
          file: file,
        );
        
        
        // Update the profile with new avatar URL
        await _profileService.upsertProfile(
          userId: _currentUser!.id,
          avatarUrl: url,
        );
        
        // Reset the removed flag since user has set a new profile picture
        setState(() {
          _profilePictureRemoved = false;
        });
        
        // Reload profile data
        await _loadProfileData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating picture: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _removeProfilePicture() async {
    if (_currentUser == null) return;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Profile Picture'),
        content: const Text('Are you sure you want to remove your profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() => _saving = true);
      try {
        // Clear the avatar URL
        await _profileService.upsertProfile(
          userId: _currentUser!.id,
          avatarUrl: '',
        );
        
        // Set flag to indicate profile picture was removed
        setState(() {
          _profilePictureRemoved = true;
        });
        
        // Reload profile data
        await _loadProfileData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture removed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing picture: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _saving = false);
      }
    }
  }


  String _getProfileImageUrl() {
    if (_profileData == null) return '';
    
    // If user has explicitly removed their profile picture, don't show any image
    if (_profilePictureRemoved) {
      return '';
    }
    
    // Check if user has set a profile picture
    final avatarUrl = _profileData!['avatar_url']?.toString();
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return avatarUrl;
    }
    
    // Fallback to first media in media_urls (onboarding uploads) only if no profile picture removed
    final media = _profileData!['media_urls'] as List<dynamic>?;
    if (media != null && media.isNotEmpty) {
      return media.first.toString();
    }
    
    return '';
  }

  String _getFullName() {
    final firstName = _profileData?['first_name'] ?? '';
    final lastName = _profileData?['last_name'] ?? '';
    return '$firstName $lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B46C1),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {
              // Show menu options
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B46C1)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Picture Section
                  Center(
                    child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _updateProfilePicture,
                        child: Container(
                            width: 140,
                            height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF6B46C1).withOpacity(0.1),
                            border: Border.all(
                              color: const Color(0xFF6B46C1),
                              width: 3,
                            ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6B46C1).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                          ),
                            child: _getProfileImageUrl().isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      _getProfileImageUrl(),
                                      fit: BoxFit.cover,
                                      cacheWidth: 140,
                                      cacheHeight: 140,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF6B46C1),
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 70,
                                          color: Color(0xFF6B46C1),
                                        );
                                      },
                                    ),
                                  )
                              : const Icon(
                                  Icons.person,
                                    size: 70,
                                  color: Color(0xFF6B46C1),
                                ),
                        ),
                      ),
                      if (_saving)
                        Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                              shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.6),
                            ),
                            child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Updating...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                            ),
                          ),
                        ),
                      Positioned(
                          bottom: 8,
                          right: 8,
                        child: GestureDetector(
                          onTap: _updateProfilePicture,
                          child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B46C1),
                              shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                color: Colors.white,
                                size: 18,
                            ),
              ),
            ),
          ),
        ],
                    ),
      ),
                  
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    _getFullName().isNotEmpty ? _getFullName() : 'Your Name',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F1F1F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Onboarding Data Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        Text(
                          'Your Profile Information',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Basics
                        _buildEditableRow('First Name', 'first_name', _profileData?['first_name']?.toString() ?? ''),
                        _buildEditableRow('Last Name', 'last_name', _profileData?['last_name']?.toString() ?? ''),
                        _buildDobRow(),
                        _buildComputedAgeRow(),
                        _buildToggleRow('Notifications', 'notifications_enabled', (_profileData?['notifications_enabled'] as bool?) ?? false),

                        // Identity
                        _buildMultiSelectRow(
                          'Pronouns',
                          'pronouns',
                          ((_profileData?['pronouns'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const []),
                          _pronounOptions,
                          maxSelections: 4,
                        ),
                        _buildVisibilitySwitch('Pronouns visible', 'pronouns_visible', (_profileData?['pronouns_visible'] as bool?) ?? true),
                        _buildSingleSelectRow(
                          'Gender',
                          'gender',
                          _profileData?['gender']?.toString() ?? '',
                          _genderOptions,
                        ),
                        _buildVisibilitySwitch('Gender visible', 'gender_visible', (_profileData?['gender_visible'] as bool?) ?? true),
                        _buildSingleSelectRow(
                          'Sexuality',
                          'sexuality',
                          _profileData?['sexuality']?.toString() ?? '',
                          _sexualityOptions,
                        ),
                        _buildVisibilitySwitch('Sexuality visible', 'sexuality_visible', (_profileData?['sexuality_visible'] as bool?) ?? true),

                        // Preferences
                        _buildMultiSelectRow(
                          'Like to date',
                          'dating_preference',
                          ((_profileData?['dating_preference'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const []),
                          _likeToDateOptions,
                        ),
                        _buildSingleSelectRow(
                          'Dating intention',
                          'dating_intention',
                          _profileData?['dating_intention']?.toString() ?? '',
                          _datingIntentionOptions,
                        ),
                        _buildVisibilitySwitch('Dating intention visible', 'dating_intention_visible', (_profileData?['dating_intention_visible'] as bool?) ?? true),
                        _buildMultiSelectRow(
                          'Type of relationship',
                          'relationship_type',
                          ((_profileData?['relationship_type'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const []),
                          _relationshipTypeOptions,
                        ),
                        _buildVisibilitySwitch('Relationship type visible', 'relationship_type_visible', (_profileData?['relationship_type_visible'] as bool?) ?? true),

                        // Location
                        _buildEditableRow('Place you live', 'location', _profileData?['location']?.toString() ?? ''),
                        _buildEditableRow('Hometown', 'hometown', _profileData?['hometown']?.toString() ?? ''),
                        _buildVisibilitySwitch('Hometown visible', 'hometown_visible', (_profileData?['hometown_visible'] as bool?) ?? true),

                        // Physical
                        _buildEditableRow('Height (cm)', 'height_cm', (_profileData?['height_cm']?.toString() ?? ''), isNumber: true),
                        _buildMultiSelectRow(
                          'Ethnicity',
                          'ethnicity',
                          ((_profileData?['ethnicity'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const []),
                          _ethnicityOptions,
                        ),
                        _buildVisibilitySwitch('Ethnicity visible', 'ethnicity_visible', (_profileData?['ethnicity_visible'] as bool?) ?? true),

                        // Family
                        _buildSingleSelectRow(
                          'Have children',
                          'children_status',
                          _profileData?['children_status']?.toString() ?? '',
                          _childrenOptions,
                        ),
                        _buildVisibilitySwitch('Children status visible', 'children_status_visible', (_profileData?['children_status_visible'] as bool?) ?? true),
                        _buildSingleSelectRow(
                          'Family plan',
                          'family_plans',
                          _profileData?['family_plans']?.toString() ?? '',
                          _familyPlanOptions,
                        ),
                        _buildVisibilitySwitch('Family plan visible', 'family_plans_visible', (_profileData?['family_plans_visible'] as bool?) ?? true),

                        // Work & Education
                        _buildEditableRow('Where do you work', 'work', _profileData?['work']?.toString() ?? ''),
                        _buildVisibilitySwitch('Work visible', 'work_visible', (_profileData?['work_visible'] as bool?) ?? true),
                        _buildEditableRow('Job title', 'job_title', _profileData?['job_title']?.toString() ?? ''),
                        _buildVisibilitySwitch('Job title visible', 'job_title_visible', (_profileData?['job_title_visible'] as bool?) ?? true),
                        _buildEditableRow('College', 'education', _profileData?['education']?.toString() ?? ''),
                        _buildVisibilitySwitch('College visible', 'education_visible', (_profileData?['education_visible'] as bool?) ?? true),
                        _buildSingleSelectRow(
                          'Highest education level',
                          'education_level',
                          _profileData?['education_level']?.toString() ?? '',
                          _educationLevelOptions,
                        ),
                        _buildVisibilitySwitch('Education level visible', 'education_level_visible', (_profileData?['education_level_visible'] as bool?) ?? true),

                        // Beliefs
                        _buildMultiSelectRow(
                          'Religious beliefs',
                          'religious_beliefs',
                          ((_profileData?['religious_beliefs'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const []),
                          _religiousBeliefOptions,
                        ),
                        _buildVisibilitySwitch('Religious beliefs visible', 'religious_beliefs_visible', (_profileData?['religious_beliefs_visible'] as bool?) ?? true),
                        _buildSingleSelectRow(
                          'Political belief',
                          'political_beliefs',
                          _profileData?['political_beliefs']?.toString() ?? '',
                          _politicalBeliefOptions,
                        ),
                        _buildVisibilitySwitch('Political belief visible', 'political_beliefs_visible', (_profileData?['political_beliefs_visible'] as bool?) ?? true),

                        // Lifestyle
                        _buildSingleSelectRow(
                          'Drink',
                          'drinking_status',
                          _profileData?['drinking_status']?.toString() ?? '',
                          _yesSometimesNoOptions,
                        ),
                        _buildVisibilitySwitch('Drink status visible', 'drinking_status_visible', (_profileData?['drinking_status_visible'] as bool?) ?? true),
                        _buildSingleSelectRow(
                          'Smoke',
                          'smoking_status',
                          _profileData?['smoking_status']?.toString() ?? '',
                          _yesSometimesNoOptions,
                        ),
                        _buildVisibilitySwitch('Smoke status visible', 'smoking_status_visible', (_profileData?['smoking_status_visible'] as bool?) ?? true),
                        _buildSingleSelectRow(
                          'Weed',
                          'weed_status',
                          _profileData?['weed_status']?.toString() ?? '',
                          _yesSometimesNoOptions,
                        ),
                        _buildVisibilitySwitch('Weed status visible', 'weed_status_visible', (_profileData?['weed_status_visible'] as bool?) ?? true),
                        _buildSingleSelectRow(
                          'Drug',
                          'drug_status',
                          _profileData?['drug_status']?.toString() ?? '',
                          _yesSometimesNoOptions,
                        ),
                        _buildVisibilitySwitch('Drug status visible', 'drug_status_visible', (_profileData?['drug_status_visible'] as bool?) ?? true),

                        _buildEditableRow('Bio', 'bio', _profileData?['bio']?.toString() ?? ''),

                        const SizedBox(height: 16),
                        _buildMediaSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Removed unused _buildInfoRow

  Widget _buildEditableRow(String label, String fieldKey, String value,
      {bool isNumber = false, bool isList = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not set' : value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _saving
                ? null
                : () => _showEditSheet(label, fieldKey, value,
                    isNumber: isNumber, isList: isList),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B46C1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySwitch(String label, String visibleKey, bool current) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: current,
            activeColor: const Color(0xFF6B46C1),
            onChanged: _saving
                ? null
                : (v) async {
                    await _saveVisibility(visibleKey, v);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildSingleSelectRow(
      String label, String fieldKey, String currentValue, List<String> options) {
    final display = currentValue.isEmpty ? 'Not set' : currentValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  display,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _saving
                ? null
                : () => _showSingleSelectSheet(label, fieldKey, currentValue, options),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B46C1),
            ),
          ),
        ],
      ),
    );
  }

  void _showSingleSelectSheet(
      String label, String fieldKey, String currentValue, List<String> options) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Select $label',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F1F1F),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...options.map((o) => ListTile(
                      title: Text(o),
                      trailing:
                          currentValue == o ? const Icon(Icons.check, color: Color(0xFF6B46C1)) : null,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _saveField(fieldKey, o);
                      },
                    )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMultiSelectRow(String label, String fieldKey, List<String> values,
      List<String> options, {int? maxSelections}) {
    final display = values.isEmpty ? 'Not set' : values.join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  display,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _saving
                ? null
                : () => _showMultiSelectSheet(
                      label,
                      fieldKey,
                      values,
                      options,
                      maxSelections: maxSelections,
                    ),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B46C1),
            ),
          ),
        ],
      ),
    );
  }

  void _showMultiSelectSheet(String label, String fieldKey, List<String> values,
      List<String> options, {int? maxSelections}) {
    final Set<String> selected = values.toSet();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding:
                  EdgeInsets.only(left: 8, right: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 8, top: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Select $label',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F1F1F),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...options.map((o) {
                    final isSelected = selected.contains(o);
                    return CheckboxListTile(
                      value: isSelected,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFF6B46C1),
                      title: Text(o),
                      onChanged: (v) {
                        setModalState(() {
                          if (isSelected) {
                            selected.remove(o);
                          } else {
                            if (maxSelections == null || selected.length < maxSelections) {
                              selected.add(o);
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _saveField(fieldKey, selected.join(','), isList: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B46C1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
  Widget _buildToggleRow(String label, String boolKey, bool current) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: current,
            activeColor: const Color(0xFF6B46C1),
            onChanged: _saving
                ? null
                : (v) async {
                    await _saveBoolean(boolKey, v);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDobRow() {
    final dobIso = _profileData?['dob']?.toString();
    final dob = dobIso != null && dobIso.isNotEmpty ? DateTime.tryParse(dobIso) : null;
    final text = dob != null ? '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}' : 'Not set';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date of Birth',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _saving ? null : _pickDob,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6B46C1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComputedAgeRow() {
    final dobIso = _profileData?['dob']?.toString();
    final dob = dobIso != null && dobIso.isNotEmpty ? DateTime.tryParse(dobIso) : null;
    final ageText = dob != null ? _calculateAge(dob).toString() : 'Not set';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Age (auto-calculated)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ageText,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDob() async {
    if (_currentUser == null) return;
    final now = DateTime.now();
    final initial = DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 10, now.month, now.day),
      helpText: 'Select your date of birth',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF6B46C1),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _saving = true);
      try {
        await _profileService.upsertProfile(userId: _currentUser!.id, dob: picked);
        await _loadProfileData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Date of birth updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update DOB: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  Widget _buildMediaSection() {
    final List<dynamic> media = (_profileData?['media_urls'] as List<dynamic>?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos & Videos',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...media.map((url) {
              final String u = url.toString();
              final isVideo = u.toLowerCase().endsWith('.mp4') || u.toLowerCase().endsWith('.mov');
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: isVideo
                          ? Center(
                              child: Icon(Icons.videocam, color: Colors.grey[600]),
                            )
                          : Image.network(
                              u,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(Icons.broken_image, color: Colors.grey[600]),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            }).toList(),
            GestureDetector(
              onTap: _saving ? null : _addMedia,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B46C1).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6B46C1)),
                ),
                child: const Center(
                  child: Icon(Icons.add, color: Color(0xFF6B46C1)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _addMedia() async {
    if (_currentUser == null) return;
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Add photos'),
                onTap: () async {
                  Navigator.pop(context);
                  final images = await picker.pickMultiImage();
                  if (images.isEmpty) return;
                  setState(() => _saving = true);
                  try {
                    final existing = ((_profileData?['media_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList()) ?? <String>[];
                    final List<String> newUrls = [];
                    for (final x in images) {
                      final url = await _profileService.uploadProfileMedia(userId: _currentUser!.id, file: File(x.path));
                      newUrls.add(url);
                    }
                    await _profileService.upsertProfile(userId: _currentUser!.id, mediaUrls: [...existing, ...newUrls]);
                    await _loadProfileData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photos added')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add photos: $e')));
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Add video'),
                onTap: () async {
                  Navigator.pop(context);
                  final video = await picker.pickVideo(source: ImageSource.gallery);
                  if (video == null) return;
                  setState(() => _saving = true);
                  try {
                    final existing = ((_profileData?['media_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList()) ?? <String>[];
                    final url = await _profileService.uploadProfileMedia(userId: _currentUser!.id, file: File(video.path));
                    await _profileService.upsertProfile(userId: _currentUser!.id, mediaUrls: [...existing, url]);
                    await _loadProfileData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video added')));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add video: $e')));
                    }
                  } finally {
                    if (mounted) setState(() => _saving = false);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditSheet(String label, String fieldKey, String initialValue,
      {bool isNumber = false, bool isList = false}) {
    final controller = TextEditingController(text: initialValue);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit $label',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType:
                    isNumber ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(
                  hintText: label,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6B46C1)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final rawValue = controller.text.trim();
                    Navigator.of(context).pop();
                    await _saveField(fieldKey, rawValue,
                        isNumber: isNumber, isList: isList);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveField(String fieldKey, String rawValue,
      {bool isNumber = false, bool isList = false}) async {
    if (_currentUser == null) return;
    setState(() => _saving = true);
    try {
      // Prepare value
      dynamic valueToSave = rawValue;
      if (isList) {
        valueToSave = rawValue
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (isNumber) {
        valueToSave = int.tryParse(rawValue);
      }

      switch (fieldKey) {
        case 'first_name':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, firstName: valueToSave as String?);
          break;
        case 'last_name':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, lastName: valueToSave as String?);
          break;
        case 'pronouns':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, pronouns: (valueToSave as List).cast<String>());
          break;
        case 'gender':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, gender: valueToSave as String?);
          break;
        case 'sexuality':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, sexuality: valueToSave as String?);
          break;
        case 'dating_preference':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, datingPreference: (valueToSave as List).cast<String>());
          break;
        case 'dating_intention':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, datingIntention: valueToSave as String?);
          break;
        case 'relationship_type':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, relationshipType: (valueToSave as List).cast<String>());
          break;
        case 'location':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, location: valueToSave as String?);
          break;
        case 'hometown':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, hometown: valueToSave as String?);
          break;
        case 'height_cm':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, heightCm: valueToSave as int?);
          break;
        case 'ethnicity':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, ethnicity: (valueToSave as List).cast<String>());
          break;
        case 'education':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, education: valueToSave as String?);
          break;
        case 'education_level':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, educationLevel: valueToSave as String?);
          break;
        case 'work':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, work: valueToSave as String?);
          break;
        case 'job_title':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, jobTitle: valueToSave as String?);
          break;
        case 'religious_beliefs':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, religiousBeliefs: (valueToSave as List).cast<String>());
          break;
        case 'political_beliefs':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, politicalBeliefs: valueToSave as String?);
          break;
        case 'drinking_status':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, drinkingStatus: valueToSave as String?);
          break;
        case 'smoking_status':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, smokingStatus: valueToSave as String?);
          break;
        case 'weed_status':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, weedStatus: valueToSave as String?);
          break;
        case 'drug_status':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, drugStatus: valueToSave as String?);
          break;
        case 'children_status':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, childrenStatus: valueToSave as String?);
          break;
        case 'bio':
          await _profileService.upsertProfile(
              userId: _currentUser!.id, bio: valueToSave as String?);
          break;
        default:
          break;
      }

      await _loadProfileData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveVisibility(String visibleKey, bool newValue) async {
    if (_currentUser == null) return;
    setState(() => _saving = true);
    try {
      switch (visibleKey) {
        case 'pronouns_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, pronounsVisible: newValue);
          break;
        case 'gender_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, genderVisible: newValue);
          break;
        case 'sexuality_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, sexualityVisible: newValue);
          break;
        case 'dating_intention_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, datingIntentionVisible: newValue);
          break;
        case 'relationship_type_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, relationshipTypeVisible: newValue);
          break;
        case 'ethnicity_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, ethnicityVisible: newValue);
          break;
        case 'children_status_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, childrenStatusVisible: newValue);
          break;
        case 'family_plans_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, familyPlansVisible: newValue);
          break;
        case 'hometown_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, hometownVisible: newValue);
          break;
        case 'work_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, workVisible: newValue);
          break;
        case 'job_title_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, jobTitleVisible: newValue);
          break;
        case 'education_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, educationVisible: newValue);
          break;
        case 'education_level_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, educationLevelVisible: newValue);
          break;
        case 'religious_beliefs_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, religiousBeliefsVisible: newValue);
          break;
        case 'political_beliefs_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, politicalBeliefsVisible: newValue);
          break;
        case 'drinking_status_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, drinkingStatusVisible: newValue);
          break;
        case 'smoking_status_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, smokingStatusVisible: newValue);
          break;
        case 'weed_status_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, weedStatusVisible: newValue);
          break;
        case 'drug_status_visible':
          await _profileService.upsertProfile(userId: _currentUser!.id, drugStatusVisible: newValue);
          break;
        default:
          break;
      }
      await _loadProfileData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update visibility: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveBoolean(String boolKey, bool newValue) async {
    if (_currentUser == null) return;
    setState(() => _saving = true);
    try {
      switch (boolKey) {
        case 'notifications_enabled':
          await _profileService.upsertProfile(userId: _currentUser!.id, notificationsEnabled: newValue);
          break;
        default:
          break;
      }
      await _loadProfileData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update setting: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
