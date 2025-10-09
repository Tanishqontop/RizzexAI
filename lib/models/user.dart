class User {
  final String id;
  final String? username;
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? gender;
  final String? sexuality;
  final String? lookingFor;
  final String? locationCity;
  final String? locationState;
  final String? locationCountry;
  final double? latitude;
  final double? longitude;
  final int? heightFeet;
  final int? heightInches;
  final List<String>? ethnicity;
  final String? religiousBelief;
  final String? politicalBelief;
  final String? educationLevel;
  final String? schoolName;
  final String? workCompany;
  final String? jobTitle;
  final String? drinking;
  final String? smokingTobacco;
  final String? smokingWeed;
  final String? drugUse;
  final String? wantsChildren;
  final String? hasChildren;
  final String? zodiacSign;
  final String? bio;
  final String? avatarUrl;
  final List<String>? profilePhotos;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    this.username,
    this.firstName,
    this.lastName,
    this.age,
    this.gender,
    this.sexuality,
    this.lookingFor,
    this.locationCity,
    this.locationState,
    this.locationCountry,
    this.latitude,
    this.longitude,
    this.heightFeet,
    this.heightInches,
    this.ethnicity,
    this.religiousBelief,
    this.politicalBelief,
    this.educationLevel,
    this.schoolName,
    this.workCompany,
    this.jobTitle,
    this.drinking,
    this.smokingTobacco,
    this.smokingWeed,
    this.drugUse,
    this.wantsChildren,
    this.hasChildren,
    this.zodiacSign,
    this.bio,
    this.avatarUrl,
    this.profilePhotos,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      sexuality: map['sexuality'] as String?,
      lookingFor: map['looking_for'] as String?,
      locationCity: map['location_city'] as String?,
      locationState: map['location_state'] as String?,
      locationCountry: map['location_country'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      heightFeet: map['height_feet'] as int?,
      heightInches: map['height_inches'] as int?,
      ethnicity: map['ethnicity'] != null 
          ? List<String>.from(map['ethnicity'] as List) 
          : null,
      religiousBelief: map['religious_belief'] as String?,
      politicalBelief: map['political_belief'] as String?,
      educationLevel: map['education_level'] as String?,
      schoolName: map['school_name'] as String?,
      workCompany: map['work_company'] as String?,
      jobTitle: map['job_title'] as String?,
      drinking: map['drinking'] as String?,
      smokingTobacco: map['smoking_tobacco'] as String?,
      smokingWeed: map['smoking_weed'] as String?,
      drugUse: map['drug_use'] as String?,
      wantsChildren: map['wants_children'] as String?,
      hasChildren: map['has_children'] as String?,
      zodiacSign: map['zodiac_sign'] as String?,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      profilePhotos: map['profile_photos'] != null 
          ? List<String>.from(map['profile_photos'] as List) 
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Factory constructor for basic profiles (when extended fields are not available)
  factory User.fromBasicMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String?,
      firstName: null,
      lastName: null,
      age: null,
      gender: null,
      sexuality: null,
      lookingFor: null,
      locationCity: null,
      locationState: null,
      locationCountry: null,
      latitude: null,
      longitude: null,
      heightFeet: null,
      heightInches: null,
      ethnicity: null,
      religiousBelief: null,
      politicalBelief: null,
      educationLevel: null,
      schoolName: null,
      workCompany: null,
      jobTitle: null,
      drinking: null,
      smokingTobacco: null,
      smokingWeed: null,
      drugUse: null,
      wantsChildren: null,
      hasChildren: null,
      zodiacSign: null,
      bio: null,
      avatarUrl: null,
      profilePhotos: null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'age': age,
      'gender': gender,
      'sexuality': sexuality,
      'looking_for': lookingFor,
      'location_city': locationCity,
      'location_state': locationState,
      'location_country': locationCountry,
      'latitude': latitude,
      'longitude': longitude,
      'height_feet': heightFeet,
      'height_inches': heightInches,
      'ethnicity': ethnicity,
      'religious_belief': religiousBelief,
      'political_belief': politicalBelief,
      'education_level': educationLevel,
      'school_name': schoolName,
      'work_company': workCompany,
      'job_title': jobTitle,
      'drinking': drinking,
      'smoking_tobacco': smokingTobacco,
      'smoking_weed': smokingWeed,
      'drug_use': drugUse,
      'wants_children': wantsChildren,
      'has_children': hasChildren,
      'zodiac_sign': zodiacSign,
      'bio': bio,
      'avatar_url': avatarUrl,
      'profile_photos': profilePhotos,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (username != null) {
      return username!;
    }
    return 'User';
  }

  String get location {
    if (locationCity != null && locationState != null) {
      return '$locationCity, $locationState';
    } else if (locationCity != null) {
      return locationCity!;
    } else if (locationState != null) {
      return locationState!;
    }
    return 'Location not specified';
  }

  String get height {
    if (heightFeet != null && heightInches != null) {
      return '$heightFeet\'$heightInches"';
    } else if (heightFeet != null) {
      return '$heightFeet\'';
    }
    return 'Height not specified';
  }

  List<String> get allPhotos {
    List<String> photos = [];
    if (avatarUrl != null) photos.add(avatarUrl!);
    if (profilePhotos != null) photos.addAll(profilePhotos!);
    return photos;
  }
}
