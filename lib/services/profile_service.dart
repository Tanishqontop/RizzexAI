import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class ProfileService {
  final _supabase = Supabase.instance.client;

  /// Private helper to execute Supabase calls with standardized error handling.
  Future<T> _guardedCall<T>(Future<T> Function() function) async {
    try {
      return await function();
    } on PostgrestException catch (e) {
      developer.log('Database error: ${e.message}', error: e);
      throw Exception('A database error occurred: ${e.code}');
    } catch (e) {
      developer.log('An unexpected error occurred: $e', error: e);
      throw Exception('An unexpected error occurred.');
    }
  }

  /// Fetches a user's profile by their ID.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    return _guardedCall(() async {
      try {
        developer.log('Fetching profile for user: $userId');
        // Select ALL columns you've added
        final response =
            await _supabase.from('profiles').select().eq('id', userId).single();
        developer.log('Profile fetched successfully: $response');
        return response;
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST116') {
          developer.log('Profile not found for user $userId');
          return null;
        }
        rethrow;
      }
    });
  }

  /// A dedicated method for uploading media files to Supabase Storage.
  Future<String> uploadProfileMedia({
    required String userId,
    required File file,
  }) async {
    return _guardedCall(() async {
      final fileExtension = file.path.split('.').last;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '$userId/$fileName';

      developer.log('Uploading media to: $filePath');
      await _supabase.storage.from('profile_media').upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      developer.log('Media uploaded successfully. Getting public URL...');
      final publicUrl =
          _supabase.storage.from('profile_media').getPublicUrl(filePath);
      developer.log('Public URL: $publicUrl');
      return publicUrl;
    });
  }

  /// Creates or updates a user's profile with any of the available fields.
  Future<void> upsertProfile({
    required String userId,
    String? username,
    String? bio,
    String? avatarUrl,
    String? firstName,
    String? lastName,
    DateTime? dob,
    bool? notificationsEnabled,
    String? location,
    List<String>? pronouns,
    bool? pronounsVisible,
    String? gender,
    bool? genderVisible,
    String? sexuality,
    bool? sexualityVisible,
    List<String>? datingPreference,
    String? datingIntention,
    bool? datingIntentionVisible,
    List<String>? relationshipType,
    bool? relationshipTypeVisible,
    int? heightCm,
    List<String>? ethnicity,
    bool? ethnicityVisible,
    String? childrenStatus,
    bool? childrenStatusVisible,
    String? familyPlans,
    bool? familyPlansVisible,
    String? hometown,
    bool? hometownVisible,
    String? work,
    bool? workVisible,
    String? jobTitle,
    bool? jobTitleVisible,
    String? education,
    bool? educationVisible,
    String? educationLevel,
    bool? educationLevelVisible,
    List<String>? religiousBeliefs,
    bool? religiousBeliefsVisible,
    String? politicalBeliefs,
    bool? politicalBeliefsVisible,
    String? drinkingStatus,
    bool? drinkingStatusVisible,
    String? smokingStatus,
    bool? smokingStatusVisible,
    String? weedStatus,
    bool? weedStatusVisible,
    String? drugStatus,
    bool? drugStatusVisible,
    List<String>? mediaUrls,
  }) async {
    return _guardedCall(() async {
      final updateData = <String, dynamic>{
        'id': userId,
      };

      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (dob != null) {
        updateData['date_of_birth'] = dob.toIso8601String();
        // Calculate age from date of birth
        final now = DateTime.now();
        int age = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
        updateData['age'] = age;
      }
      if (notificationsEnabled != null)
        updateData['notifications_enabled'] = notificationsEnabled;
      if (location != null) updateData['location'] = location;
      if (pronouns != null) updateData['pronouns'] = pronouns;
      if (pronounsVisible != null)
        updateData['pronouns_visible'] = pronounsVisible;
      if (gender != null) updateData['gender'] = gender;
      if (genderVisible != null) updateData['gender_visible'] = genderVisible;
      if (sexuality != null) updateData['sexuality'] = sexuality;
      if (sexualityVisible != null)
        updateData['sexuality_visible'] = sexualityVisible;
      if (datingPreference != null)
        updateData['dating_preference'] = datingPreference;
      if (datingIntention != null)
        updateData['dating_intention'] = datingIntention;
      if (datingIntentionVisible != null)
        updateData['dating_intention_visible'] = datingIntentionVisible;
      if (relationshipType != null)
        updateData['relationship_type'] = relationshipType;
      if (relationshipTypeVisible != null)
        updateData['relationship_type_visible'] = relationshipTypeVisible;
      if (heightCm != null) updateData['height_cm'] = heightCm;
      if (ethnicity != null) updateData['ethnicity'] = ethnicity;
      if (ethnicityVisible != null)
        updateData['ethnicity_visible'] = ethnicityVisible;
      if (childrenStatus != null)
        updateData['children_status'] = childrenStatus;
      if (childrenStatusVisible != null)
        updateData['children_status_visible'] = childrenStatusVisible;
      if (familyPlans != null) updateData['family_plans'] = familyPlans;
      if (familyPlansVisible != null)
        updateData['family_plans_visible'] = familyPlansVisible;
      if (hometown != null) updateData['hometown'] = hometown;
      if (hometownVisible != null)
        updateData['hometown_visible'] = hometownVisible;
      if (work != null) updateData['work'] = work;
      if (workVisible != null) updateData['work_visible'] = workVisible;
      if (jobTitle != null) updateData['job_title'] = jobTitle;
      if (jobTitleVisible != null)
        updateData['job_title_visible'] = jobTitleVisible;
      if (education != null) updateData['education'] = education;
      if (educationVisible != null)
        updateData['education_visible'] = educationVisible;
      if (educationLevel != null)
        updateData['education_level'] = educationLevel;
      if (educationLevelVisible != null)
        updateData['education_level_visible'] = educationLevelVisible;
      if (religiousBeliefs != null)
        updateData['religious_beliefs'] = religiousBeliefs;
      if (religiousBeliefsVisible != null)
        updateData['religious_beliefs_visible'] = religiousBeliefsVisible;
      if (politicalBeliefs != null)
        updateData['political_beliefs'] = politicalBeliefs;
      if (politicalBeliefsVisible != null)
        updateData['political_beliefs_visible'] = politicalBeliefsVisible;
      if (drinkingStatus != null)
        updateData['drinking_status'] = drinkingStatus;
      if (drinkingStatusVisible != null)
        updateData['drinking_status_visible'] = drinkingStatusVisible;
      if (smokingStatus != null) updateData['smoking_status'] = smokingStatus;
      if (smokingStatusVisible != null)
        updateData['smoking_status_visible'] = smokingStatusVisible;
      if (weedStatus != null) updateData['weed_status'] = weedStatus;
      if (weedStatusVisible != null)
        updateData['weed_status_visible'] = weedStatusVisible;
      if (drugStatus != null) updateData['drug_status'] = drugStatus;
      if (drugStatusVisible != null)
        updateData['drug_status_visible'] = drugStatusVisible;
      if (mediaUrls != null) updateData['media_urls'] = mediaUrls;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      developer.log('Upserting profile for user: $userId');
      await _supabase.from('profiles').upsert(updateData);
      developer.log('Profile upserted successfully for user: $userId');
    });
  }
}
