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
    int? age = map['age'] as int?;
    if (age == null) {
      String? dobString;
      final dobRaw = map['date_of_birth'] ?? map['dob'];
      if (dobRaw is String) {
        dobString = dobRaw;
      } else if (dobRaw != null) {
        dobString = dobRaw.toString();
      }
      if (dobString != null && dobString.isNotEmpty) {
        try {
          final dob = DateTime.parse(dobString);
          final now = DateTime.now();
          age = now.year - dob.year;
          if (now.month < dob.month ||
              (now.month == dob.month && now.day < dob.day)) {
            age--;
          }
        } catch (_) {}
      }
    }

    int? heightFeet = map['height_feet'] as int?;
    int? heightInches = map['height_inches'] as int?;
    if (heightFeet == null && map['height_cm'] != null) {
      final totalInches = ((map['height_cm'] as num) / 2.54).round();
      heightFeet = totalInches ~/ 12;
      heightInches = totalInches % 12;
    }

    String? religiousBelief = map['religious_belief'] as String?;
    if (religiousBelief == null && map['religious_beliefs'] != null) {
      final beliefs = map['religious_beliefs'];
      if (beliefs is List && beliefs.isNotEmpty) {
        religiousBelief = beliefs.first.toString();
      } else if (beliefs is String) {
        religiousBelief = beliefs;
      }
    }

    final photosRaw = map['profile_photos'] ?? map['media_urls'];
    List<String>? profilePhotos;
    if (photosRaw is List) {
      profilePhotos = photosRaw.map((e) => e.toString()).toList();
    }

    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return User(
      id: map['id'] as String,
      username: map['username'] as String?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      age: age,
      gender: map['gender'] as String?,
      sexuality: map['sexuality'] as String?,
      lookingFor: map['looking_for'] as String?,
      locationCity:
          map['location_city'] as String? ?? map['location'] as String?,
      locationState: map['location_state'] as String?,
      locationCountry: map['location_country'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      heightFeet: heightFeet,
      heightInches: heightInches,
      ethnicity: map['ethnicity'] != null
          ? List<String>.from(map['ethnicity'] as List)
          : null,
      religiousBelief: religiousBelief,
      politicalBelief:
          map['political_belief'] as String? ?? map['political_beliefs'] as String?,
      educationLevel:
          map['education_level'] as String? ?? map['education'] as String?,
      schoolName: map['school_name'] as String?,
      workCompany: map['work_company'] as String? ?? map['work'] as String?,
      jobTitle: map['job_title'] as String?,
      drinking: map['drinking'] as String? ?? map['drinking_status'] as String?,
      smokingTobacco:
          map['smoking_tobacco'] as String? ?? map['smoking_status'] as String?,
      smokingWeed:
          map['smoking_weed'] as String? ?? map['weed_status'] as String?,
      drugUse: map['drug_use'] as String? ?? map['drug_status'] as String?,
      wantsChildren:
          map['wants_children'] as String? ?? map['children_status'] as String?,
      hasChildren: map['has_children'] as String?,
      zodiacSign: map['zodiac_sign'] as String?,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      profilePhotos: profilePhotos,
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }

  /// Fallback mapping that still reads available profile fields.
  factory User.fromBasicMap(Map<String, dynamic> map) {
    try {
      return User.fromMap(map);
    } catch (_) {
      return User(
        id: map['id'] as String,
        username: map['username'] as String?,
        firstName: map['first_name'] as String?,
        lastName: map['last_name'] as String?,
        profilePhotos: map['media_urls'] is List
            ? List<String>.from(map['media_urls'] as List)
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
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
    final photos = <String>[];
    if (avatarUrl != null && !_isProfileVideoUrl(avatarUrl!)) {
      photos.add(avatarUrl!);
    }
    if (profilePhotos != null) {
      photos.addAll(
        profilePhotos!.where((url) => !_isProfileVideoUrl(url)),
      );
    }
    return photos;
  }
}

bool _isProfileVideoUrl(String url) {
  const videoExtensions = {'mp4', 'mov', 'webm', 'avi', 'mkv', 'm4v'};
  final path = Uri.tryParse(url)?.path ?? url;
  final ext = path.split('.').last.toLowerCase();
  return videoExtensions.contains(ext);
}
