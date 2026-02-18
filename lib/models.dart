// Data models for the Flutter app that match the enhanced backend

class User {
  final String id;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? profilePicture;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      profilePicture: json['profilePicture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'profilePicture': profilePicture,
    };
  }
}

class UserProfile {
  final String? id;
  final String userId;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? bio;
  final String? city;
  final String? occupation;
  final List<String> interests;
  final int? height;
  final String? education;
  final double? latitude;
  final double? longitude;
  final String? primaryPhotoUrl;
  final List<String> photoUrls;
  final bool isVerified;
  final bool isOnline;
  final DateTime? lastActiveAt;
  final bool isActive;
  final String? lifestyle;
  final String? relationshipGoals;
  final bool isPremium;
  final String? gender;
  final String? preferences;
  final String? drinking;
  final String? smoking;
  final String? workout;
  final List<String> languages;
  final String? voicePromptUrl;

  UserProfile({
    this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.bio,
    this.city,
    this.occupation,
    this.interests = const [],
    this.height,
    this.education,
    this.latitude,
    this.longitude,
    this.primaryPhotoUrl,
    this.photoUrls = const [],
    this.isVerified = false,
    this.isOnline = false,
    this.lastActiveAt,
    this.isActive = true,
    this.lifestyle,
    this.relationshipGoals,
    this.isPremium = false,
    this.gender,
    this.preferences,
    this.drinking,
    this.smoking,
    this.workout,
    this.languages = const [],
    this.voicePromptUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final dynamic rawUserId =
        json['userId'] ?? json['UserId'] ?? json['id'] ?? json['Id'];
    final userId = rawUserId?.toString() ?? '';

    final rawName = json['name'] ?? json['Name'] ?? '';
    final firstName =
        json['firstName'] ?? json['FirstName'] ?? _splitName(rawName).$1;
    final lastName =
        json['lastName'] ?? json['LastName'] ?? _splitName(rawName).$2;

    final dob = _resolveBirthDate(
      json['dateOfBirth'] ?? json['DateOfBirth'],
      json['age'] ?? json['Age'],
    );

    final interestsList = json['interests'] ?? json['Interests'];
    final languagesList = json['languages'] ?? json['Languages'];
    final photoUrls = _extractPhotoUrls(json);

    return UserProfile(
      id: json['id']?.toString() ?? json['Id']?.toString(),
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dob,
      bio: json['bio'] ?? json['Bio'],
      city: json['city'] ?? json['City'],
      occupation: json['occupation'] ?? json['Occupation'],
      interests: interestsList is List
          ? interestsList.map((e) => e.toString()).toList()
          : const [],
      height: _toInt(json['height'] ?? json['Height']),
      education: json['education'] ?? json['Education'],
      latitude: _toDouble(json['latitude'] ?? json['Latitude']),
      longitude: _toDouble(json['longitude'] ?? json['Longitude']),
      primaryPhotoUrl: json['primaryPhotoUrl'] ??
          json['PrimaryPhotoUrl'] ??
          (photoUrls.isNotEmpty ? photoUrls.first : null),
      photoUrls: photoUrls,
      isVerified: json['isVerified'] ?? json['IsVerified'] ?? false,
      isOnline: json['isOnline'] ?? json['IsOnline'] ?? false,
      lastActiveAt: _parseDate(json['lastActiveAt'] ?? json['LastActiveAt']),
      isActive: json['isActive'] ?? json['IsActive'] ?? true,
      lifestyle: json['lifestyle'] ?? json['Lifestyle'],
      relationshipGoals: json['relationshipGoals'] ?? json['RelationshipGoals'],
      isPremium: json['isPremium'] ?? json['IsPremium'] ?? false,
      gender: json['gender'] ?? json['Gender'],
      preferences: json['preferences'] ?? json['Preferences'],
      drinking: json['drinking'] ?? json['Drinking'],
      smoking: json['smoking'] ?? json['Smoking'],
      workout: json['workout'] ?? json['Workout'],
      languages: languagesList is List
          ? languagesList.map((e) => e.toString()).toList()
          : const [],
      voicePromptUrl: json['voicePromptUrl'] ?? json['VoicePromptUrl'],
    );
  }

  static (String, String) _splitName(String fullName) {
    if (fullName.trim().isEmpty) {
      return ('', '');
    }
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return (parts.first, '');
    }
    final first = parts.first;
    final last = parts.sublist(1).join(' ');
    return (first, last);
  }

  static DateTime _resolveBirthDate(dynamic rawDate, dynamic rawAge) {
    if (rawDate is String) {
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null) {
        return parsed;
      }
    }

    final age =
        rawAge is num ? rawAge.toInt() : int.tryParse(rawAge?.toString() ?? '');
    if (age != null && age > 0) {
      final now = DateTime.now();
      return DateTime(now.year - age, now.month, now.day);
    }

    return DateTime.now().subtract(const Duration(days: 25 * 365));
  }

  static List<String> _extractPhotoUrls(Map<String, dynamic> json) {
    final photos = json['photoUrls'] ?? json['PhotoUrls'];
    if (photos is List) {
      return photos.map((e) => e.toString()).toList();
    }

    final urls = <String>[];
    final primary = json['primaryPhotoUrl'] ?? json['PrimaryPhotoUrl'];
    if (primary != null && primary.toString().isNotEmpty) {
      urls.add(primary.toString());
    }
    return urls;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'bio': bio,
      'city': city,
      'occupation': occupation,
      'interests': interests,
      'height': height,
      'education': education,
      'latitude': latitude,
      'longitude': longitude,
      'primaryPhotoUrl': primaryPhotoUrl,
      'photoUrls': photoUrls,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'isActive': isActive,
      'lifestyle': lifestyle,
      'relationshipGoals': relationshipGoals,
      'isPremium': isPremium,
      'gender': gender,
      'preferences': preferences,
      'drinking': drinking,
      'smoking': smoking,
      'workout': workout,
      'languages': languages,
    };
  }

  int get age {
    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      return age - 1;
    }
    return age;
  }

  String get fullName => '$firstName $lastName';
}

class SwipeResponse {
  final bool isMatch;
  final String? matchId;
  final String message;

  SwipeResponse({required this.isMatch, this.matchId, required this.message});

  factory SwipeResponse.fromJson(Map<String, dynamic> json) {
    return SwipeResponse(
      isMatch: json['isMatch'] ?? json['isMutualMatch'] ?? false,
      matchId: (json['matchId'] ?? json['MatchId'])?.toString(),
      message: json['message'] ?? json['Message'] ?? '',
    );
  }
}

class Match {
  final String id;
  final String userId1;
  final String userId2;
  final DateTime matchedAt;
  final bool isActive;
  final UserProfile? otherUserProfile;

  Match({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.matchedAt,
    this.isActive = true,
    this.otherUserProfile,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'].toString(),
      userId1: json['userId1'].toString(),
      userId2: json['userId2'].toString(),
      matchedAt: DateTime.parse(json['matchedAt']),
      isActive: json['isActive'] ?? true,
      otherUserProfile: json['otherUserProfile'] != null
          ? UserProfile.fromJson(json['otherUserProfile'])
          : null,
    );
  }
}

class CompatibilityScore {
  final double overallScore;
  final double locationScore;
  final double ageScore;
  final double interestsScore;
  final double educationScore;
  final double lifestyleScore;

  CompatibilityScore({
    required this.overallScore,
    required this.locationScore,
    required this.ageScore,
    required this.interestsScore,
    required this.educationScore,
    required this.lifestyleScore,
  });

  factory CompatibilityScore.fromJson(Map<String, dynamic> json) {
    return CompatibilityScore(
      overallScore: (json['overallScore'] ?? 0).toDouble(),
      locationScore: (json['locationScore'] ?? 0).toDouble(),
      ageScore: (json['ageScore'] ?? 0).toDouble(),
      interestsScore: (json['interestsScore'] ?? 0).toDouble(),
      educationScore: (json['educationScore'] ?? 0).toDouble(),
      lifestyleScore: (json['lifestyleScore'] ?? 0).toDouble(),
    );
  }
}

class SearchFilters {
  final int? minAge;
  final int? maxAge;
  final String? city;
  final double? maxDistance;
  final List<String>? interests;
  final String? education;
  final int page;
  final int pageSize;

  const SearchFilters({
    this.minAge,
    this.maxAge,
    this.city,
    this.maxDistance,
    this.interests,
    this.education,
    this.page = 1,
    this.pageSize = 10,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'minAge': minAge,
      'maxAge': maxAge,
      'location': city,
      'maxDistance': maxDistance,
      if (interests != null && interests!.isNotEmpty) 'interests': interests,
      'education': education,
      'page': page,
      'pageSize': pageSize,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? json['sentAt'] ?? '') ??
          DateTime.now(),
      isRead: json['isRead'] ?? false,
      type: MessageType.values[json['type'] ?? 0],
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.index,
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    MessageType? type,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      readAt: readAt ?? this.readAt,
    );
  }
}

enum MessageType {
  text,
  image,
  emoji,
}

/// A candidate profile returned by the matchmaking service for swiping
class PromptAnswer {
  final String question;
  final String answer;

  PromptAnswer({required this.question, required this.answer});

  factory PromptAnswer.fromJson(Map<String, dynamic> json) {
    return PromptAnswer(
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
    );
  }
}

class MatchCandidate {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final List<String> photoUrls;
  final int age;
  final String? bio;
  final String? city;
  final double? distanceKm;
  final double compatibility;
  final List<String> interestsOverlap;
  final String? occupation;
  final List<PromptAnswer> prompts;
  final String? voicePromptUrl;
  final int? height;
  final String? education;
  final String? gender;
  final bool isVerified;

  MatchCandidate({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.photoUrls = const [],
    required this.age,
    this.bio,
    this.city,
    this.distanceKm,
    this.compatibility = 0.0,
    this.interestsOverlap = const [],
    this.occupation,
    this.prompts = const [],
    this.voicePromptUrl,
    this.height,
    this.education,
    this.gender,
    this.isVerified = false,
  });

  factory MatchCandidate.fromJson(Map<String, dynamic> json) {
    final photos = <String>[];
    if (json['photoUrls'] is List) {
      photos.addAll((json['photoUrls'] as List).map((e) => e.toString()));
    }
    final primaryPhoto =
        json['primaryPhotoUrl'] ?? json['photoUrl'] ?? (photos.isNotEmpty ? photos.first : null);

    final promptsList = <PromptAnswer>[];
    if (json['prompts'] is List) {
      for (final p in json['prompts'] as List) {
        if (p is Map<String, dynamic>) {
          promptsList.add(PromptAnswer.fromJson(p));
        }
      }
    }

    return MatchCandidate(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      displayName: json['displayName'] ?? json['name'] ?? json['firstName'] ?? 'Unknown',
      photoUrl: primaryPhoto?.toString(),
      photoUrls: photos,
      age: _resolveAge(json),
      bio: json['bio'],
      city: json['city'],
      distanceKm: json['distanceKm'] != null ? (json['distanceKm'] as num).toDouble() : null,
      compatibility: json['compatibility'] != null
          ? (json['compatibility'] as num).toDouble()
          : (json['compatibilityScore'] != null
              ? (json['compatibilityScore'] as num).toDouble()
              : 0.0),
      interestsOverlap: json['interestsOverlap'] is List
          ? (json['interestsOverlap'] as List).map((e) => e.toString()).toList()
          : (json['interests'] is List
              ? (json['interests'] as List).map((e) => e.toString()).toList()
              : const []),
      occupation: json['occupation'],
      prompts: promptsList,
      voicePromptUrl: json['voicePromptUrl'],
      height: json['height'] is num ? (json['height'] as num).toInt() : null,
      education: json['education'],
      gender: json['gender'],
      isVerified: json['isVerified'] == true,
    );
  }

  static int _resolveAge(Map<String, dynamic> json) {
    if (json['age'] is int) return json['age'] as int;
    if (json['age'] is num) return (json['age'] as num).toInt();
    if (json['dateOfBirth'] != null) {
      final dob = DateTime.tryParse(json['dateOfBirth'].toString());
      if (dob != null) {
        final now = DateTime.now();
        var age = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          age--;
        }
        return age;
      }
    }
    return 0;
  }
}

/// Alias for UserProfile used in the API facade layer
typedef MemberProfile = UserProfile;

/// Summary of a match used in the matches list
class MatchSummary {
  final String matchId;
  final String matchedUserId;
  final String displayName;
  final String? photoUrl;
  final DateTime matchedAt;
  final String? lastMessage;

  MatchSummary({
    required this.matchId,
    required this.matchedUserId,
    required this.displayName,
    this.photoUrl,
    required this.matchedAt,
    this.lastMessage,
  });

  factory MatchSummary.fromJson(Map<String, dynamic> json) {
    return MatchSummary(
      matchId: (json['matchId'] ?? json['id'] ?? '').toString(),
      matchedUserId: (json['matchedUserId'] ?? json['userId'] ?? json['otherUserId'] ?? '').toString(),
      displayName: json['displayName'] ?? json['name'] ?? 'Unknown',
      photoUrl: json['photoUrl'] ?? json['primaryPhotoUrl'],
      matchedAt: DateTime.tryParse(json['matchedAt']?.toString() ?? '') ?? DateTime.now(),
      lastMessage: json['lastMessage'],
    );
  }
}
